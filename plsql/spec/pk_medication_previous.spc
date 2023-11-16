/*-- Last Change Revision: $Rev: 2028799 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_medication_previous IS

    TYPE t_rec_prev_medication_list IS RECORD(
        pharm     VARCHAR2(4000),
        dt        VARCHAR2(30),
        prof_name VARCHAR2(800),
        id_prof   professional.id_professional%TYPE,
        subject   VARCHAR2(30));

    TYPE t_cur_prev_medication_list IS REF CURSOR RETURN t_rec_prev_medication_list;
    TYPE t_coll_prev_medication_list IS TABLE OF t_rec_prev_medication_list;

    /********************************************************************************************
    * Create dosage string.
    *
    * @param i_lang              language
    * @param i_qty               prescribed quantity
    * @param i_unit_qty          quantity unit measure id
    * @param i_freq              prescribed frequency
    * @param i_unit_freq         frequency unit measure id
    * @param i_duration          prescribed duration
    * @param i_unit_dur          duration unit_measure id
    * @param i_dt_begin          prescription data begin
    * @param i_dt_end            prescription data end
    * @param i_prof              professional array 
    *
    * @return                Return VARCHAR2  
    *
    * @author                Patrícia Neto
    * @version               0.1
    * @since                 2007/12/08
    ********************************************************************************************/

    FUNCTION get_dosage_format
    (
        i_lang      IN language.id_language%TYPE,
        i_qty       IN NUMBER,
        i_unit_qty  IN NUMBER,
        i_freq      IN NUMBER,
        i_unit_freq IN NUMBER,
        i_duration  IN NUMBER,
        i_unit_dur  IN NUMBER,
        i_dt_begin  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof      IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Create/modify reported medication
    *
    * @param    I_LANG                     language
    * @param    I_EPISODE                  episode id
    * @param    I_PATIENT                  patient id
    * @param    I_PROF                     professional array
    * @param    I_PRESC_PHARM              prescription id (id_prescription_pharm)
    * @param    I_ID_PAT_MEDIC             reported medication id (id_pat_medication_list)
    * @param    I_EMB                      package id
    * @param    I_MED                      medication id
    * @param    I_PROD_MED                 free text medication id
    * @param    I_FLG_STATUS               status: A - current; P - not current; C - canceled
    * @param    I_DT_BEGIN                 reported medication data bagin
    * @param    I_NOTES                    notes
    * @param    I_FLG_TYPE                 type: Flag: E - extern; I - internal medication
    * @param    I_PROF_CAT_TYPE            professional category
    * @param    I_QTY                      medication quantity
    * @param    I_ID_UNIT_MEASURE_QTY      medication quantity unit measure id
    * @param    I_FREQ                     medication frequency
    * @param    I_ID_UNIT_MEASURE_FREQ     medication frequency unit measure id 
    * @param    I_DURATION                 medication duration
    * @param    I_ID_UNIT_MEASURE_FDUR     medication duration unit measure id
    * @param    I_EPIS_DOC                 epis documentation id
    * @param    I_FLG_NO_MED              'Y', se NO HOME MEDICATION está seleccionado e 'N', se ''NO HOME MEDICATION'' não está seleccionado
    * @param    I_ADV_REACTIONS            adverse reactions
    * @param    I_FLG_NO_MED               destination of medication
    * @param    O_ID_PAT_MEDIC_LIST        created reported medication id
    * @param    O_ERROR                    error
    *
    * @return                Return BOOLEAN  
    *
    * @author                SS
    * @version               0.1
    * @since                 2006/06/12
    *
    * @author alter          Patrícia Neto
    * @since                 2007/OUT/16
    *
    ********************************************************************************************/

    FUNCTION set_pat_medication
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_presc_pharm    IN table_number,
        i_drug_req_det   IN table_number,
        i_drug_presc_det IN table_number,
        i_id_pat_medic   IN table_number,
        i_emb            IN table_varchar,
        --i_med                   IN table_number,
        i_med                   IN table_varchar,
        i_drug                  IN table_varchar,
        i_med_id_type           IN table_varchar,
        i_prod_med              IN table_varchar,
        i_flg_status            IN table_varchar,
        i_dt_begin              IN table_varchar,
        i_notes                 IN table_varchar,
        i_flg_type              IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_qty                   IN table_number,
        i_id_unit_measure_qty   IN table_number,
        i_freq                  IN table_number,
        i_id_unit_measure_freq  IN table_number,
        i_duration              IN table_number,
        i_id_unit_measure_dur   IN table_number,
        i_dt_start_pat_med_tstz IN table_varchar,
        i_dt_end_pat_med_tstz   IN table_varchar,
        i_epis_doc              IN NUMBER,
        i_vers                  IN table_varchar,
        i_flg_no_med            IN pat_medication_list.flg_no_med%TYPE,
        i_adv_reactions         IN table_varchar,
        i_med_destination       IN table_varchar,
        i_flg_take_type         IN table_varchar DEFAULT NULL,
        i_id_presc_directions   IN presc_directions.id_presc_directions%TYPE DEFAULT NULL,
        i_id_cdr_call           IN table_number DEFAULT NULL, --cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_id_pat_medic_list     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create reported medication in text free mode
    *
    * @param    I_LANG                 language
    * @param    I_EPISODE              episode id
    * @param    I_PATIENT              patient id
    * @param    I_PROF                 professional array
    * @param    I_PROD_MED_DECR        free text reported medication
    * @param    I_FLG_STATUS           STATUS: A - current; P - not current; C - canceled
    * @param    I_DT_BEGIN             data begining
    * @param    I_NOTES                notes
    * @param    I_PROF_CAT_TYPE        professional category
    * @param    I_QTY                  reported medication quantity
    * @param    I_ID_UNIT_MEASURE_QTY  reported medication quantity unit measure id
    * @param    I_FREQ                 reported medication frequency
    * @param    I_ID_UNIT_MEASURE_FREQ reported medication frequency unit measure id
    * @param    I_DURATION             reported medication duration
    * @param    I_ID_UNIT_MEASURE_FDUR reported medication  duration id
    * @param    I_FLG_SHOW             FLG, 'Y' ou 'N', depending if shows message   
    * @param    I_EPIS_DOC             epis documentation id
    * @param    O_PROF_MED             created reported medication
    * @param    O_ERROR                error
    *
    * @return                Return BOOLEAN  
    *
    * @author                Patrícia Neto
    * @version               0.1
    * @since                 2007/OUT/16
    *
    ********************************************************************************************/

    FUNCTION set_outros_produtos
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_patient               IN patient.id_patient%TYPE,
        i_prof                  IN profissional,
        i_prod_med_decr         IN table_varchar,
        i_med_id_type           IN table_varchar,
        i_flg_status            IN table_varchar,
        i_dt_begin              IN table_varchar,
        i_notes                 IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_qty                   IN table_number,
        i_id_unit_measure_qty   IN table_number,
        i_freq                  IN table_number,
        i_id_unit_measure_freq  IN table_number,
        i_duration              IN table_number,
        i_id_unit_measure_dur   IN table_number,
        i_dt_start_pat_med_tstz IN table_varchar,
        i_dt_end_pat_med_tstz   IN table_varchar,
        i_flg_show              IN VARCHAR2,
        i_epis_doc              IN NUMBER,
        i_vers                  IN table_varchar,
        i_flg_no_med            IN pat_medication_list.flg_no_med%TYPE,
        i_flg_take_type         IN table_varchar DEFAULT NULL,
        i_id_presc_directions   IN presc_directions.id_presc_directions%TYPE DEFAULT NULL,
        i_id_cdr_call           IN table_number DEFAULT NULL, --cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_prod_med              OUT pk_types.cursor_type,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set the changes in the previous medications rows states (current/not current)
    *
    * @ param i_lang                       language
    * @ param i_prof                       professional array
    * @ param i_id_patient                 patient id
    * @ param i_id_episode                 episode id
    * @ param i_id_pat_medic               reported medication id (id_pat_medication_list)
    * @ param i_flg_status                 status: A - current; P - not current; C - canceled
    * @ param o_error                      error message
    *
    * @return                TRUE if success and FALSE otherwise   
    *
    * @author                Orlando Antunes
    * @version               0.1
    * @since                 2008/04/29
    *
    * @author                José Brito
    * @version               2.6.0.5
    * @since                 2011/01/17
    ********************************************************************************************/
    FUNCTION call_set_pat_medication_states
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_pat_medic IN table_number,
        i_flg_status   IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_medication_states
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        --id pat_medication_list
        i_id_pat_medic IN table_number,
        --pat_medication_list.flg_status
        i_flg_status IN table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_review_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN drug_prescription.id_episode%TYPE,
        i_action       IN VARCHAR2 DEFAULT NULL,
        i_review_notes IN VARCHAR2 DEFAULT NULL,
        i_dt_review    IN VARCHAR2 DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    ----------------------------------------------------------------------------------------------------------
    -- PARÂMETROS
    ----------------------------------------------------------------------------------------------------------

    -- Geral
    g_error VARCHAR2(2000);
    g_found BOOLEAN;
    g_flg_type_adm      CONSTANT prescription.flg_type%TYPE := 'A';
    g_flg_type_ext      CONSTANT prescription.flg_type%TYPE := 'E';
    g_flg_type_int      CONSTANT prescription.flg_type%TYPE := 'I';
    g_flg_type_rel_prev CONSTANT prescription.flg_type%TYPE := 'Z';
    g_flg_type_reported CONSTANT prescription.flg_type%TYPE := 'R';
    g_flg_type_prod_med CONSTANT VARCHAR2(1) := 'O';
    g_flg_freq          CONSTANT VARCHAR2(1) := 'M';
    g_flg_pesq          CONSTANT VARCHAR2(1) := 'P';
    g_no                CONSTANT VARCHAR2(1) := 'N';
    g_yes               CONSTANT VARCHAR2(1) := 'Y';
    g_sim               CONSTANT VARCHAR2(1) := 'S';
    g_drug              CONSTANT VARCHAR2(1) := 'M';
    g_sysdate           CONSTANT DATE := SYSDATE;
    g_sysdate_tstz      CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    g_sysdate_char      VARCHAR2(50);
    g_sysdate_tstz_char VARCHAR2(50);
    g_flg_inactive CONSTANT VARCHAR2(1) := 'I';
    g_touch_option CONSTANT VARCHAR2(1) := 'D';
    g_free_text    CONSTANT VARCHAR2(1) := 'N';
    g_available    CONSTANT VARCHAR2(1) := 'Y';
    --g_usa          CONSTANT VARCHAR2(255) := 'USA';
    g_selected CONSTANT VARCHAR2(1) := 'S'; -- selected 
    g_pt       CONSTANT VARCHAR2(255) := 'PT';

    --VALORES DA BD INFARMED
    g_mnsrm     CONSTANT inf_class_disp.class_disp_id%TYPE := 1;
    g_msrm_e    CONSTANT inf_class_disp.class_disp_id%TYPE := 4;
    g_msrm_ra   CONSTANT inf_class_disp.class_disp_id%TYPE := 10;
    g_msrm_rb   CONSTANT inf_class_disp.class_disp_id%TYPE := 11; --já não é utilizado
    g_msrm_rc   CONSTANT inf_class_disp.class_disp_id%TYPE := -1; --12 já não é utilizado
    g_msrm_r_ea CONSTANT inf_class_disp.class_disp_id%TYPE := 13;
    g_msrm_r_ec CONSTANT inf_class_disp.class_disp_id%TYPE := 15;
    g_emb_hosp  CONSTANT inf_class_disp.class_disp_id%TYPE := 20;
    g_disp_in_v CONSTANT inf_class_disp.class_disp_id%TYPE := 100;

    g_prod_diabetes   CONSTANT inf_tipo_prod.tipo_prod_id%TYPE := 13;
    g_flg_manip_ext   CONSTANT prescription.flg_sub_type%TYPE := 'ME';
    g_flg_dietary_ext CONSTANT prescription.flg_sub_type%TYPE := 'DE';

    -- sys_domain
    g_presc_type_domain           CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION.FLG_TYPE';
    g_pat_med_list_domain         CONSTANT sys_domain.code_domain%TYPE := 'PAT_MEDICATION_LIST.FLG_STATUS';
    g_presc_pharm_generico_domain CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION_PHARM.GENERICO';
    g_epis_doc_satus              CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DOCUMENTATION.FLG_STATUS';
    g_epis_anam_status            CONSTANT sys_domain.code_domain%TYPE := 'EPIS_ANAMNESIS.FLG_STATUS';
    g_epis_rev_sys_status         CONSTANT sys_domain.code_domain%TYPE := 'EPIS_REVIEW_SYSTEMS.FLG_STATUS';
    g_epis_obs_status             CONSTANT sys_domain.code_domain%TYPE := 'EPIS_OBSERVATION.FLG_STATUS';
    g_domain_epis_doc_flg_status  CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DOCUMENTATION.FLG_STATUS';
    g_domain_relatos sys_domain.code_domain%TYPE := 'RELATOS'; -- relatos

    -- sys_message
    g_presc_manip_message   sys_message.code_message%TYPE := 'PRESCRIPTION_MANIP_T007';
    g_presc_dietary_message sys_message.code_message%TYPE := 'PRESCRIPTION_DIETARY_T003';
    g_error_001_message     sys_message.code_message%TYPE := 'COMMON_M001';

    -------- titutlos                   
    g_presc_t_8        sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T008';
    g_presc_t_43       sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T043';
    g_search_crit_t011 sys_message.code_message%TYPE := 'SEARCH_CRITERIA_T011';
    g_presc_rec_t059   sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T059';
    g_doc_t006         sys_message.code_message%TYPE := 'DOCUMENTATION_T006';
    g_presc_rec_t_004  sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T004';
    g_presc_rec_t_062  sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T062';
    g_presc_rec_t_063  sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T063';
    g_presc_rec_t_066  sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T066';
    g_presc_rec_t_067  sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T067';
    g_presc_rec_t_009  sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T009';

    -------- mensagens   
    g_presc_pharm_m004 CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_PHARM_M004';
    g_search_crit_m003 CONSTANT sys_message.code_message%TYPE := 'SEARCH_CRITERIA_M003';
    g_drug_presc_m011  CONSTANT sys_message.code_message%TYPE := 'DRUG_PRESC_M011';
    g_doc_m013         CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M013';

    g_presc_rec_m001      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REPORTED_M001';
    g_presc_rec_m014      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M014';
    g_presc_rec_m015      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M015';
    g_presc_rec_m019      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M019';
    g_presc_rec_m020      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M020';
    g_presc_rec_m026      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M026'; -- New directions for use
    g_presc_rec_m032      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M032'; -- canceled on:
    g_presc_det_m036      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_DET_M036'; -- Indicação para continuar em:
    g_prescrito_a_message CONSTANT sys_message.code_message%TYPE := ' DRUG_PRESC_M010'; -- prescrito a:
    g_presc_rec_m012      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M012'; -- activo
    g_presc_rec_m013      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M013'; -- não activo
    g_presc_rec_m038      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_M038'; -- Com notas
    g_presc_rec_t009      CONSTANT sys_message.code_message%TYPE := 'PRESCRIPTION_REC_T009';

    --buttons
    g_forward_button_msg CONSTANT sys_message.code_message%TYPE := 'COMMON_M022';
    g_back_button_msg    CONSTANT sys_message.code_message%TYPE := 'COMMON_M023';

    -- sys_config
    g_presc_type             CONSTANT sys_config.id_sys_config%TYPE := 'PRESCRIPTION_TYPE';
    g_prescription_usa       CONSTANT sys_config.id_sys_config%TYPE := 'PRESCRIPTION_USA';
    g_show_conversion_screen CONSTANT sys_config.id_sys_config%TYPE := 'PRESC_SHOW_CONVERSION_SCREEN';

    -- translation
    g_trans_advanc_in_013 CONSTANT translation.code_translation%TYPE := 'ADVANCED_INPUT_FIELD.CODE_ADVANCED_INPUT_FIELD.13';
    g_trans_advanc_in_014 CONSTANT translation.code_translation%TYPE := 'ADVANCED_INPUT_FIELD.CODE_ADVANCED_INPUT_FIELD.14';
    g_code_unit_measure   CONSTANT translation.code_translation%TYPE := 'UNIT_MEASURE.CODE_UNIT_MEASURE.';

    -- Drug
    g_flg_new_fluid  CONSTANT VARCHAR2(1) := 'N';
    g_flg_new_vacina CONSTANT VARCHAR2(1) := 'V';

    -- Precription 
    g_presc_print CONSTANT prescription.flg_status%TYPE := 'P';
    g_presc_temp  CONSTANT prescription.flg_status%TYPE := 'T';
    g_presc_can   CONSTANT prescription.flg_status%TYPE := 'C';

    -- Drug_req_det
    g_drug_req_det_temp   CONSTANT drug_req_det.flg_status%TYPE := 'T';
    g_drug_req_det_cancel CONSTANT drug_req_det.flg_status%TYPE := 'C';

    -- Drug_req
    g_drug_req_temp CONSTANT drug_req.flg_status%TYPE := 'T';
    g_drug_req_can  CONSTANT drug_req.flg_status%TYPE := 'C';

    -- Drug_presc_det
    g_presc_det_req  CONSTANT drug_presc_det.flg_status%TYPE := 'R';
    g_presc_det_pend CONSTANT drug_presc_det.flg_status%TYPE := 'D';
    g_presc_det_can  CONSTANT drug_presc_det.flg_status%TYPE := 'C';

    -- pat_medication_list
    g_pat_med_list_can  CONSTANT pat_medication_list.flg_status%TYPE := 'C'; -- cancelado
    g_pat_med_list_pas  CONSTANT pat_medication_list.flg_status%TYPE := 'P'; -- passivo
    g_pat_med_list_act  CONSTANT pat_medication_list.flg_status%TYPE := 'A'; -- activo
    g_pat_med_list_ina  CONSTANT pat_medication_list.flg_status%TYPE := 'I'; -- inactivo
    g_pat_med_list_del  CONSTANT pat_medication_list.flg_status%TYPE := 'D'; -- deleted
    g_pat_med_list_next CONSTANT pat_medication_list.flg_status%TYPE := 'N'; -- reported medication from previous episodes

    g_pat_med_list_con CONSTANT VARCHAR2(1) := 'C'; -- continue
    g_pat_med_list_int CONSTANT VARCHAR2(1) := 'I'; -- interrompido

    -- pat_medication_hist_list
    g_pat_med_hist_list_act CONSTANT pat_medication_hist_list.flg_status%TYPE := 'A'; -- activo

    -- epis_documentation
    g_epis_doc_act CONSTANT epis_documentation.flg_status%TYPE := 'A';
    g_epis_doc_can CONSTANT epis_documentation.flg_status%TYPE := 'C';
    g_epis_doc_out CONSTANT epis_documentation.flg_status%TYPE := 'O';

    -- epis_anamnesis
    g_epis_anam_temp CONSTANT epis_anamnesis.flg_temp%TYPE := 'T';
    g_epis_anam_can  CONSTANT epis_anamnesis.flg_type%TYPE := 'C';
    g_epis_anam_act  CONSTANT epis_anamnesis.flg_type%TYPE := 'A';

    -- epis_review_systems
    g_epis_rev_sys_act CONSTANT epis_review_systems.flg_status%TYPE := 'A';

    -- doc_area
    g_doc_area_rev_sys   CONSTANT doc_area.id_doc_area%TYPE := 22; --Review of system
    g_doc_area_complaint CONSTANT doc_area.id_doc_area%TYPE := 20; --Complaint
    g_doc_area_hist_ill  CONSTANT doc_area.id_doc_area%TYPE := 21; --History present illness
    g_doc_area_phy_exam  CONSTANT doc_area.id_doc_area%TYPE := 28; --physical exam   

    -- epis_observation
    g_epis_obs_act CONSTANT VARCHAR2(1) := 'A';
    g_epis_obs_e   CONSTANT VARCHAR2(1) := 'E';

    -- prescription_instr_hist
    g_flg_change_sta   CONSTANT prescription_instr_hist.flg_change%TYPE := 'S'; -- change status
    g_flg_change_mod   CONSTANT prescription_instr_hist.flg_change%TYPE := 'M'; -- change MODIFY ORDER
    g_flg_change_ref   CONSTANT prescription_instr_hist.flg_change%TYPE := 'R'; -- change REFILL
    g_flg_change_presc CONSTANT prescription_instr_hist.flg_change%TYPE := 'P'; -- prescrition

    g_flg_status_int     CONSTANT prescription_instr_hist.flg_status_new%TYPE := 'I'; -- interrompido
    g_flg_status_con     CONSTANT prescription_instr_hist.flg_status_new%TYPE := 'C'; -- continue
    g_presc_pharm_table  CONSTANT prescription_instr_hist.prescription_table%TYPE := 'PRESCRIPTION_PHARM';
    g_drug_req_det_table CONSTANT prescription_instr_hist.prescription_table%TYPE := 'DRUG_REQ_DET';
    g_pat_med_lis_table  CONSTANT prescription_instr_hist.prescription_table%TYPE := 'PAT_MEDICATION_LIST';

    -- prescription_pharm
    g_presc_pharm_int CONSTANT prescription_pharm.flg_status%TYPE := 'I'; -- interrompido
    g_presc_pharm_can CONSTANT prescription_pharm.flg_status%TYPE := 'C'; -- cancelado

    -- pml_dep_clin_serv
    --g_pml_dcs_dcs  CONSTANT pml_dep_clin_serv.flg_pml_dcs_type%TYPE := 'DCS'; -- pesquisa por id_dep_clin_serv
    g_pml_dcs_mt_e CONSTANT pml_dep_clin_serv.flg_med_type%TYPE := 'E'; -- medicação externa
    g_pml_dcs_mt_i CONSTANT pml_dep_clin_serv.flg_med_type%TYPE := 'I'; -- medicação interna
    g_freq         CONSTANT pml_dep_clin_serv.flg_type%TYPE := 'M';
    --

    SUBTYPE pmhl_id_unit_measure_freq_t IS pat_medication_hist_list.id_unit_measure_freq%TYPE;
    g_prev_med_adv_reaction_list CONSTANT VARCHAR2(100) := 'PAT_MEDICATION_LIST.ADVERSE_REACTIONS';
    g_prev_med_destination_list  CONSTANT VARCHAR2(100) := 'PAT_MEDICATION_LIST.MEDICATION_DESTINATION';
    --
    g_mec_session CONSTANT notes_config.notes_code%TYPE := 'MEC';

    --cancel reasons
    g_cancel_rea_area      CONSTANT cancel_rea_area.intern_name%TYPE := 'MEDICATION_CANCEL';
    g_discontinue_rea_area CONSTANT cancel_rea_area.intern_name%TYPE := 'MEDICATION_DISCONTINUE';
    g_hold_rea_area        CONSTANT cancel_rea_area.intern_name%TYPE := 'MEDICATION_HOLD';

    g_inactive sys_domain.val%TYPE := 'P'; --relatos inactivos

    --review_detail data for reported medication
    g_set_reviewed      CONSTANT VARCHAR2(20) := 'REVIEWED';
    g_set_not_reviewed  CONSTANT VARCHAR2(20) := 'NOT_REVIEWED';
    g_set_part_reviewed CONSTANT VARCHAR2(20) := 'PART_REVIEWED';

    g_last_reviewed_text      CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M076';
    g_partially_reviewed_text CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M072';
    g_reviewed_text           CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M073';
    g_not_reviewed_text       CONSTANT VARCHAR2(30) := 'MEDICATION_DETAILS_M074';
END;
/
