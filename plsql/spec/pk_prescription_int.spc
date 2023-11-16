/*-- Last Change Revision: $Rev: 2028869 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_prescription_int IS

    -- Author  : SUSANA
    -- Created : 25-10-2007 8:40:47
    -- Purpose : Functions for internal medication

    TYPE r_advanced_input IS RECORD(
        id_advanced_input           advanced_input.id_advanced_input%TYPE,
        id_advanced_input_field     advanced_input_field.id_advanced_input_field%TYPE,
        id_advanced_input_field_det advanced_input_field_det.id_advanced_input_field_det%TYPE,
        descr                       VARCHAR2(1000));

    TYPE t_advanced_input IS TABLE OF r_advanced_input;
    /********************************************************************************************
     * Cancel a prescription (not used by Flash).
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_drug_presc_det         Prescription ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_notes                  Cancelation notes
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/26
    **********************************************************************************************/
    FUNCTION call_cancel_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_prof           IN profissional,
        i_notes          IN drug_presc_det.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Cancel a prescription.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_drug_presc_det         Prescription ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_notes                  Cancelation notes
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/26
    **********************************************************************************************/

    FUNCTION cancel_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_prof           IN profissional,
        i_notes          IN drug_presc_det.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_prof           IN profissional,
        i_notes          IN drug_presc_det.notes_cancel%TYPE,
        i_commit         IN VARCHAR2,
        o_error          OUT t_error_out
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
    FUNCTION insert_drug_presc_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_drug_presc_det   IN table_number,
        i_subject          IN table_varchar,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_flg_commit       IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_drug_presc_det   IN table_number,
        i_subject          IN table_varchar,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Cancels the administration of a take.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_drug_presc_plan        Planned administration ID
     * @param i_dt_next                Next administration date
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_notes                  Cancel notes
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         Nuno Antunes
     * @version                        0.1
     * @since                          2011/01/03
    **********************************************************************************************/
    FUNCTION cancel_adm_take
    (
        i_lang                IN language.id_language%TYPE,
        i_drug_presc_plan     IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_dt_next             IN VARCHAR2,
        i_prof                IN profissional,
        i_notes               IN drug_presc_plan.notes%TYPE,
        i_id_cancel_reason    IN drug_presc_plan.id_cancel_reason%TYPE,
        i_cancel_reason_descr IN drug_presc_plan.cancel_reason_descr%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    
    
    /********************************************************************************************
     * Update cosign columns (not used by Flash).
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_prof_cat_type          Professional's category type
     * @param i_table                  Name of the table to update
     * @param id_table                 ID of the record to update
     * @param i_co_sign                Columns to update
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/26
    **********************************************************************************************/

    FUNCTION update_co_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_table         IN VARCHAR2,
        id_table        IN NUMBER,
        i_co_sign       IN co_sign_obj,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------------------------
    --------
    --------
    g_next_take_mode VARCHAR2(4000) := 'PLAN_DATE';
    g_found          BOOLEAN;
    g_sysdate        DATE;
    g_sysdate_tstz   TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    g_sysdate_char   VARCHAR2(50);
    g_error          VARCHAR2(2000);

    g_drug_req     drug_req.flg_status%TYPE;
    g_drug_exec    drug_req.flg_status%TYPE;
    g_drug_canc    drug_req.flg_status%TYPE;
    g_drug_pend    drug_req.flg_status%TYPE;
    g_drug_res     drug_req.flg_status%TYPE;
    g_drug_part    drug_req.flg_status%TYPE;
    g_drug_rejeita drug_req.flg_status%TYPE;

    g_flg_cancel VARCHAR2(1);

    g_drug_det_pend drug_req_det.flg_status%TYPE;
    g_drug_det_req  drug_req_det.flg_status%TYPE;
    g_drug_det_exec drug_req_det.flg_status%TYPE;
    g_drug_det_fini drug_req_det.flg_status%TYPE;
    g_drug_det_part drug_req_det.flg_status%TYPE;
    g_drug_det_canc drug_req_det.flg_status%TYPE;
    g_drug_det_desc drug_req_det.flg_status%TYPE;

    g_drug_sup_prep    drug_req_supply.flg_status%TYPE;
    g_drug_sup_ppt     drug_req_supply.flg_status%TYPE;
    g_drug_sup_trans   drug_req_supply.flg_status%TYPE;
    g_drug_sup_exec    drug_req_supply.flg_status%TYPE;
    g_drug_sup_canc    drug_req_supply.flg_status%TYPE;
    g_drug_sup_aux     drug_req_supply.flg_status%TYPE;
    g_drug_sup_end_aux drug_req_supply.flg_status%TYPE;
    g_drug_sup_utente  drug_presc_det.flg_status%TYPE;

    g_cancel_rea_area      cancel_rea_area.intern_name%TYPE;
    g_discontinue_rea_area cancel_rea_area.intern_name%TYPE;
    g_hold_rea_area        cancel_rea_area.intern_name%TYPE;

    g_flg_available VARCHAR2(1);

    g_drug_available     drug.flg_available%TYPE;
    g_pharma_class_avail drug_pharma_class.flg_available%TYPE;
    g_pharma_avail       drug_pharma.flg_available%TYPE;
    g_drug_form_avail    drug_form.flg_available%TYPE;
    g_drug_route_avail   drug_route.flg_available%TYPE;
    g_drug_execute       drug_dep_clin_serv.flg_type%TYPE;
    g_drug_freq          drug_dep_clin_serv.flg_type%TYPE;

    g_icon     VARCHAR2(1);
    g_date     VARCHAR2(1);
    g_no_color VARCHAR2(1);

    g_flg_other category.flg_type%TYPE;

    g_room_pref prof_room.flg_pref%TYPE;

    -- NOVAS VARIÁVEIS GLOBAIS PARA A FERRAMENTA DE PRESCRIÇÃO

    g_flg_freq VARCHAR2(1);
    g_flg_pesq VARCHAR2(1);
    g_no       VARCHAR2(1);
    g_yes      VARCHAR2(1);
    g_read     VARCHAR2(1);

    g_flg_int         drug_req.flg_type%TYPE;
    g_descr_int       pk_translation.t_desc_translation;
    g_flg_adm         drug_req.flg_type%TYPE;
    g_flg_unidose     drug_req.flg_type%TYPE;
    g_flg_ext         VARCHAR2(1);
    g_flg_manip_ext   prescription.flg_sub_type%TYPE;
    g_flg_manip_int   prescription.flg_sub_type%TYPE;
    g_flg_dietary_ext prescription.flg_sub_type%TYPE;
    g_flg_dietary_int prescription.flg_sub_type%TYPE;

    g_total_return   drug_instit_justification.flg_type%TYPE;
    g_partial_return drug_instit_justification.flg_type%TYPE;

    g_presc_take_sos  drug_presc_det.flg_take_type%TYPE;
    g_presc_take_nor  drug_presc_det.flg_take_type%TYPE;
    g_presc_take_uni  drug_presc_det.flg_take_type%TYPE;
    g_presc_take_cont drug_presc_det.flg_take_type%TYPE;
    g_presc_take_eter drug_presc_det.flg_take_type%TYPE;
    g_presc_take_irre drug_presc_det.flg_take_type%TYPE;

    g_flg_temp drug_presc_det.flg_status%TYPE;

    g_det_temp   drug_presc_det.flg_status%TYPE;
    g_det_req    drug_presc_det.flg_status%TYPE;
    g_det_pend   drug_presc_det.flg_status%TYPE;
    g_det_exe    drug_presc_det.flg_status%TYPE;
    g_det_fin    drug_presc_det.flg_status%TYPE;
    g_det_can    drug_presc_det.flg_status%TYPE;
    g_det_intr   drug_presc_det.flg_status%TYPE;
    g_det_reject drug_presc_det.flg_status%TYPE;
    g_det_susp   drug_presc_det.flg_status%TYPE;

    g_drug drug.flg_type%TYPE;

    g_selected VARCHAR2(1);

    g_flg_time_epis drug_prescription.flg_time%TYPE;
    g_flg_time_next drug_prescription.flg_time%TYPE;
    g_flg_time_betw drug_prescription.flg_time%TYPE;

    g_presc_type_int drug_prescription.flg_type%TYPE;

    g_presc_plan_stat_adm        drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_nadm       drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_can        drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_req        drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_pend       drug_presc_plan.flg_status%TYPE;
    g_presc_plan_stat_adm_cancel drug_presc_plan.flg_status%TYPE;

    g_flg_doctor     category.flg_type%TYPE;
    g_flg_nurse      category.flg_type%TYPE;
    g_flg_pharmacist category.flg_type%TYPE;
    g_flg_aux        category.flg_type%TYPE;
    g_flg_phys       category.flg_type%TYPE;
    g_flg_tec        category.flg_type%TYPE;

    g_color_red VARCHAR2(1);

    ---------
    g_patient_active     VARCHAR2(1);
    g_pat_blood_active   VARCHAR2(1);
    g_default_hplan_y    VARCHAR2(1);
    g_hplan_active       VARCHAR2(1);
    g_epis_cancel        VARCHAR2(1);
    g_no_triage          VARCHAR2(1);
    g_epis_diag_act      VARCHAR2(1);
    g_pat_allergy_cancel VARCHAR2(1);
    g_pat_habit_cancel   VARCHAR2(1);
    g_pat_problem_cancel VARCHAR2(1);
    g_pat_notes_cancel   VARCHAR2(1);

    g_epis_consult epis_type.id_epis_type%TYPE;
    g_epis_urg     epis_type.id_epis_type%TYPE;
    g_epis_surgery epis_type.id_epis_type%TYPE;
    g_epis_obs     epis_type.id_epis_type%TYPE;
    g_epis_intern  epis_type.id_epis_type%TYPE;
    g_epis_social  epis_type.id_epis_type%TYPE;
    g_epis_cs      epis_type.id_epis_type%TYPE;

    g_months_sign VARCHAR2(200);
    g_days_sign   VARCHAR2(200);
    g_exception EXCEPTION;
    g_cat_prof       category.flg_prof%TYPE;
    g_category_avail category.flg_available%TYPE;

    g_movem_term movement.flg_status%TYPE;

    g_flg_without VARCHAR2(2);

    g_inp_software NUMBER;

    g_chnm           sys_config.value%TYPE;
    g_tolerance_time NUMBER(4, 2);

    g_drug_presc_det_n drug_presc_det.flg_take_type%TYPE;
    g_drug_presc_det_u drug_presc_det.flg_take_type%TYPE;
    g_drug_presc_det_c drug_presc_det.flg_take_type%TYPE;
    g_drug_presc_det_a drug_presc_det.flg_take_type%TYPE;
    g_drug_presc_det_s drug_presc_det.flg_take_type%TYPE;
    l_co_sign          co_sign_obj := co_sign_obj(NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    g_flg_co_sign      VARCHAR2(1);

    g_domain_take sys_domain.code_domain%TYPE;
    g_domain_time sys_domain.code_domain%TYPE;

    g_flg_new_fluid drug_req.flg_status%TYPE;
    g_drug_interv   VARCHAR2(1);

    g_presc_flg_type sys_domain.code_domain%TYPE;

    g_domain_status sys_domain.code_domain%TYPE;

    g_active VARCHAR2(1);

    g_advanced_input     advanced_input.id_advanced_input%TYPE;
    g_all_institution    institution.id_institution%TYPE;
    g_all_software       software.id_software%TYPE;
    g_multichoice_keypad advanced_input_field.type%TYPE;
    g_num_keypad         advanced_input_field.type%TYPE;
    g_date_keypad        advanced_input_field.type%TYPE;

    g_version prescription_std_instr.version%TYPE;

    g_flg_therapeutic VARCHAR(1);

    g_drug_presc_det VARCHAR2(200);

    g_dosage VARCHAR2(1);

    g_min_unit_measure   NUMBER(24);
    g_hours_unit_measure NUMBER(24);
    g_day_unit_measure   NUMBER(24);
    g_week_unit_measure  NUMBER(24);

    g_hour_seconds       NUMBER(24);
    g_minute_seconds     NUMBER(24);
    g_day_seconds        NUMBER(24);
    g_week_seconds       NUMBER(24);
    g_presc_det_req_hosp drug_presc_det.flg_status%TYPE;

    -- translation
    g_trans_advanc_in_013 translation.code_translation%TYPE := 'ADVANCED_INPUT_FIELD.CODE_ADVANCED_INPUT_FIELD.13';
    g_trans_advanc_in_014 translation.code_translation%TYPE := 'ADVANCED_INPUT_FIELD.CODE_ADVANCED_INPUT_FIELD.14';

    g_adv_input_presc_dosage  advanced_input.id_advanced_input%TYPE := 25;
    g_adv_input_presc_dos_ext advanced_input.id_advanced_input%TYPE := 34;
    g_adv_input_presc_int     advanced_input.id_advanced_input%TYPE := 43;

    g_qty_for_24h VARCHAR2(1);
    g_total_qty   VARCHAR2(1);

    g_presc_det_intr drug_presc_det.flg_status%TYPE := 'I'; -- interrompido
    g_presc_det_sus  drug_presc_det.flg_status%TYPE := 'S';

    g_code_unit_measure translation.code_translation%TYPE := 'UNIT_MEASURE.CODE_UNIT_MEASURE.';
    g_time_duration     VARCHAR2(50);
    g_time_freq         VARCHAR2(50);

    g_type_adm           VARCHAR2(1) := 'A';
    g_type_int           VARCHAR2(2) := 'I';
    g_type_ext           VARCHAR2(1) := 'E';
    g_type_other_product VARCHAR2(1) := 'O';
    g_flg_type_i         drug_req.flg_type%TYPE;

    g_local      CONSTANT VARCHAR2(255) := 'LOCAL';
    g_soro       CONSTANT VARCHAR2(255) := 'SORO';
    g_other_prod CONSTANT VARCHAR2(255) := 'OUTROS_PROD';
    g_compound   CONSTANT VARCHAR2(255) := 'COMPOUND';

    g_message_inicio sys_message.code_message%TYPE := 'PRESCRIPTION_T003'; --Início
    g_message_fim    sys_message.code_message%TYPE := 'PRESCRIPTION_T004'; -- Fim
    g_hospital CONSTANT VARCHAR2(255) := 'HOSPITAL';

    g_cosign_type_drug_req    CONSTANT co_sign_task.flg_type%TYPE := 'DR';
    g_cosign_type_drug_presc  CONSTANT co_sign_task.flg_type%TYPE := 'P';
    g_cosign_type_presc_pharm CONSTANT co_sign_task.flg_type%TYPE := 'PP';

    g_prescription_usa       sys_config.id_sys_config%TYPE := 'PRESCRIPTION_USA';
    g_presc_group_flg_ok_usa sys_domain.code_domain%TYPE := 'PRESC_GROUP_FLG_OK_USA'; --  'Medication group with non-obligatory instruction'

    g_not_applicable NUMBER(1) := 1;
    g_date_defined   NUMBER(1) := 2;
    g_not_defined    NUMBER(1) := 3;

    g_interv_request CONSTANT interv_dep_clin_serv.flg_type%TYPE := 'P';

    g_mec_session CONSTANT notes_config.notes_code%TYPE := 'MEC';

    -- prescription version
    g_prescription_version_br CONSTANT VARCHAR2(2 CHAR) := 'BR';
    --CPOE MED task states
    g_med_cpoe_a CONSTANT VARCHAR2(1) := 'A'; -- cpoe tasks in active state
    g_med_cpoe_i CONSTANT VARCHAR2(1) := 'I'; -- cpoe tasks in inactive state - cancelled, discontinued and finished tasks.
    g_med_cpoe_y CONSTANT VARCHAR2(1) := 'Y'; -- cpoe tasks in created state - draft created.
    g_med_cpoe_w CONSTANT VARCHAR2(1) := 'W'; -- cpoe tasks in expired state.

    g_constructed_fluids CONSTANT mi_med.id_drug%TYPE := '7515';

    g_task_type_local CONSTANT NUMBER(2) := 10; --task type for local when sync_task

    g_cancel_take_rea_area     cancel_rea_area.intern_name%TYPE := 'CANCEL TAKE';
    g_cancel_take_adm_rea_area cancel_rea_area.intern_name%TYPE := 'CANCEL_ADM_TAKE';
    g_presc_use_flg_multidose CONSTANT VARCHAR2(200) := 'PRESCRIPTION_DISPENSE_USE_FLG_MULTIDOSE';

END pk_prescription_int;
/
