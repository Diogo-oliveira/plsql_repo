/*-- Last Change Revision: $Rev: 2028867 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_prescription IS


    /********************************************************************************************
     * Cancel the prescription of one drug (not the entire prescription).
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_presc_pharm            id_prescription_pharm (drug prescription ID)
     * @param i_emb                    Drug ID
     * @param i_flg_type               Type of prescription
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error   
     *
     * @value i_flg_type               {*} 'E' Outside prescription
                                       {*} 'I' Internal prescription
                                       {*} 'R' Reported prescription
                                       {*} ''  cancel on the prescription screen
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/11
    **********************************************************************************************/

    FUNCTION cancel_pharm_prescr
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_presc_pharm   IN prescription_pharm.id_prescription_pharm%TYPE,
        i_emb           IN VARCHAR2,
        i_flg_type      IN VARCHAR2,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pharm_prescr
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_presc_pharm   IN prescription_pharm.id_prescription_pharm%TYPE,
        i_emb           IN VARCHAR2,
        i_flg_type      IN VARCHAR2,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_commit        IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    ----------------------------------------------------------------------------------------------------------

    /********************************************************************************************
     * Get the parent GROUP_ID.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_group_id               "Child GROUP_ID"
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     *
     * @return                         number -> GROUP_ID
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/07
    **********************************************************************************************/

    FUNCTION get_id_parent
    (
        i_lang     IN language.id_language%TYPE,
        i_group_id IN NUMBER
    ) RETURN NUMBER;

    ----------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------
    /** @headcom
    *  Obter preço de uma embalagem.   
    * Não é chamada pelo Flash.
    *
    * @param      I_EMB             ID da embalagem
    * @param      I_TYPE            Tipo de preço: 
                 0 - PVP
                                             1 - Preço de Referência
                                             2 - Preço de Referência para Pensionistas
    *
    * @return     varchar2
    * @author     SS
    * @version    0.1
    * @since      2006/03/14
    */

    FUNCTION get_price
    (
        i_emb  IN inf_emb.emb_id%TYPE,
        i_type IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION get_patient_recm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_reconcile_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN drug_prescription.id_episode%TYPE,
        i_action          IN VARCHAR2 DEFAULT NULL,
        i_reconcile_notes IN VARCHAR2 DEFAULT NULL,
        i_dt_reconcile    IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    
    /********************************************************************************************
     * Check if this drug was already prescribed in this episode.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_emb                    Drug ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_flg_show               Indicate if there's a message to show to the user
     * @param o_msg                    Message
     * @param o_msg_title              Message title
     * @param o_button                 Buttons to show
     * @param o_error                  Error   
     *
     * @return                         Y - if i_group_id has "child" records; N - otherwise
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/09
    **********************************************************************************************/

    FUNCTION exist_ext_prescription
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_emb       IN table_varchar,
        i_prof      IN profissional,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    
    /********************************************************************************************
    * This function checks if a drug being prescribed is marked as chronic medication
    * and can issue a warning if parametrized
    *
    * @param i_lang         in Language ID
    * @param i_episode      IN episode.id_episode
    * @param i_patient      IN patient.id_patient
    * @param i_emb          IN table_varchar,
    * @param i_prof         IN profissional
    * @param o_flg_show     OUT VARCHAR2
    * @param o_msg          OUT VARCHAR2
    * @param o_msg_title    OUT VARCHAR2
    * @param o_button       OUT VARCHAR2      
    * @param o_chronic_med  OUT VARCHAR2
    * @param o_error        out t_error_out
    *
    * @return                Return Boolean - Success / Fail
    *
    * @raises
    *
    * @author                Nuno Antunes
    * @version               V.2.5.0.7.8
    * @since                 2010/05/31
    ********************************************************************************************/
    FUNCTION is_chronic_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_emb         IN table_varchar,
        i_prof        IN profissional,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_chronic_med OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    
    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        i_commit              IN VARCHAR2 DEFAULT NULL,
        --
        i_id_other_prod_list    IN table_number,
        i_other_prod_name_list  IN table_varchar,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        --
        i_qty_inst      IN table_number,
        i_unit_qty_inst IN table_number,
        i_freq          IN table_number,
        i_unit_freq     IN table_number,
        i_duration      IN table_number,
        i_unit_duration IN table_number,
        --
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Create a prescription.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_patient                Patient ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_emb                    Array: Drug ID
     * @param i_qty                    Array: number of prescribed packages
     * @param i_generico               Array: indicates if the physician allows a generic substitute
     * @param i_dosage                 Array: dosage (PT: posologia)
     * @param i_prof_cat_type          Professional's category type
     * @param i_test                   indicates if is necessary to test if this drug was already prescribed in this episode    
     * @param o_flg_show               Indicate if there's a message to show to the user
     * @param o_msg                    Message
     * @param o_msg_title              Message title
     * @param o_button                 Buttons to show
     * @param o_id_prescription_pharm  PRESCRIPTION_PHARM_ID created   
     * @param o_error                  Error   
     *
     * @return                         Y - if i_group_id has "child" records; N - otherwise
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/09
    **********************************************************************************************/

    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        --
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_ext_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_emb                 IN table_varchar,
        i_qty                 IN table_number,
        i_generico            IN table_varchar,
        i_dosage              IN table_varchar,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_test                IN VARCHAR2,
        i_pat_medication_list IN table_number,
        --
        i_id_other_prod_list   IN table_number,
        i_other_prod_name_list IN table_varchar,
        -- Para as instruções parametrizadas por defeito
        i_qty_inst      IN table_number,
        i_unit_qty_inst IN table_number,
        i_freq          IN table_number,
        i_unit_freq     IN table_number,
        i_duration      IN table_number,
        i_unit_duration IN table_number,
        --
        i_commit IN VARCHAR2 DEFAULT NULL,
        --
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_id_prescription_pharm OUT prescription_pharm.id_prescription_pharm%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --
    g_sysdate           DATE;
    g_sysdate_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
    g_error             VARCHAR2(2000);
    g_found             BOOLEAN;
    g_sysdate_char      VARCHAR2(50);
    g_sysdate_tstz_char VARCHAR2(50);

    g_presc_type_int drug_prescription.flg_type%TYPE;

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

    g_domain_take sys_domain.code_domain%TYPE;
    g_domain_time sys_domain.code_domain%TYPE;
    g_replace_brand_for_generic CONSTANT sys_domain.code_domain%TYPE := 'REPLACE_BRAND_FOR_GENERIC';

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
    g_exterior    CONSTANT VARCHAR2(255) := 'EXTERIOR';
    g_dietetico   CONSTANT VARCHAR2(255) := 'DIETETICOS';
    g_manipulados CONSTANT VARCHAR2(255) := 'MANIPULADO';
    -- TIPOS DE MEDICAÇÃO
    g_type_adm VARCHAR2(1) := 'A';
    g_type_int VARCHAR2(2) := 'I';
    g_type_ext VARCHAR2(1) := 'E';

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
    /*G_PRINT_N         VARCHAR2(1);
    G_PRINT_R         VARCHAR2(1);
    G_PRINT_E         VARCHAR2(1);
    */
    g_inst_type_cs institution.flg_type%TYPE;
    g_inst_type_hs institution.flg_type%TYPE;
    g_inst_type_cp institution.flg_type%TYPE;

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
    g_stat_pend         drug_prescription.flg_status%TYPE;
    g_stat_req          drug_prescription.flg_status%TYPE;
    g_stat_intr         drug_prescription.flg_status%TYPE;
    g_stat_canc         drug_prescription.flg_status%TYPE;
    g_presc_det_bolus   drug_presc_det.flg_status%TYPE;
    g_stat_fin          drug_prescription.flg_status%TYPE;
    g_flg_new_fluid     drug_req.flg_status%TYPE;
    g_stat_exec         drug_prescription.flg_status%TYPE;
    g_flg_take_type_sos drug_prescription.flg_status%TYPE;
    l_co_sign           co_sign_obj := co_sign_obj(NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    g_flg_co_sign       VARCHAR2(1);
    g_stat_adm          drug_prescription.flg_status%TYPE;

    -- drug_req
    g_drug_req_req     drug_req.flg_status%TYPE;
    g_drug_req_pend    drug_req.flg_status%TYPE;
    g_drug_req_exe     drug_req.flg_status%TYPE;
    g_drug_req_rejeita drug_req.flg_status%TYPE;
    g_drug_req_parc    drug_req.flg_status%TYPE;

    -- sys_config
    g_brand_necessary sys_config.id_sys_config%TYPE := 'BRAND_NECESSARY';

    --
    g_presc_type CONSTANT VARCHAR2(20) := 'PRESCRIPTION_TYPE';
    --g_usa        CONSTANT VARCHAR2(255) := 'USA';
    g_br CONSTANT VARCHAR2(255) := 'BR';
    g_nl CONSTANT VARCHAR2(255) := 'NL';
    g_gb CONSTANT VARCHAR2(255) := 'GB';
    --
    g_mec_session CONSTANT notes_config.notes_code%TYPE := 'MEC';

    g_chronic_cancel_rea_area cancel_rea_area.intern_name%TYPE;

    g_nurse_can_edit_presc     sys_config.id_sys_config%TYPE := 'NURSE_CAN_EDIT_PRESC';
    g_prof_temp_can_edit_presc sys_config.id_sys_config%TYPE := 'PROF_TEMP_CAN_EDIT_PRESC';
    g_prof_cat_nurse  CONSTANT VARCHAR2(1) := 'N';
    g_prof_cat_doctor CONSTANT VARCHAR2(1) := 'D';

    --reconcile_detail data for medication
    g_set_reconciled      CONSTANT VARCHAR2(20) := 'RECONCILED';
    g_set_not_reconciled  CONSTANT VARCHAR2(20) := 'NOT_RECONCILED';
    g_set_part_reconciled CONSTANT VARCHAR2(20) := 'PART_RECONCILED';

END;
/
