/*-- Last Change Revision: $Rev: 2029036 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_vacc IS

    SUBTYPE obj_name IS VARCHAR2(30 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    TYPE time_det IS RECORD(
        t_min  VARCHAR2(100),
        t_hour VARCHAR2(100),
        t_day  VARCHAR2(100));

    TYPE table_time_det IS TABLE OF time_det;

    TYPE p_adm_det_rec IS RECORD(
        det_name  sys_message.desc_message%TYPE,
        det_value VARCHAR2(4000),
        desc_resp VARCHAR2(4000),
        flg_show  VARCHAR2(10),
        id_test   NUMBER(24));

    TYPE p_adm_det_cur IS REF CURSOR RETURN p_adm_det_rec;
    TYPE table_adm_det IS TABLE OF p_adm_det_rec;

    FUNCTION get_gap_between_doses
    (
        i_lang   IN language.id_language%TYPE,
        i_n_dose IN vacc_dose.n_dose%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN NUMBER;

    FUNCTION get_dose_age
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        --i_datetake IN DATE --drug_presc_plan.dt_take%TYPE
        i_datetake_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_ndose
    (
        i_lang    IN language.id_language%TYPE,
        i_vaccine IN vacc.id_vacc%TYPE
    ) RETURN NUMBER;

    FUNCTION get_vacc_med_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc         IN vacc.id_vacc%TYPE,
        i_orig         IN VARCHAR2,
        o_vacc_med_ext OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_application_spot_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notes_advers_react_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --

    FUNCTION create_presc_vacc
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN drug_prescription.id_episode%TYPE,
        i_prof     IN profissional,
        i_pat      IN patient.id_patient%TYPE,
        i_flg_time IN drug_prescription.flg_time%TYPE,
        --i_dt_begin      IN DATE, --drug_prescription.dt_begin%TYPE,
        --i_dt_begin_tstz IN drug_prescription.dt_begin_tstz%TYPE,
        i_dt_begin      IN VARCHAR2,
        i_notes         IN drug_presc_plan.notes%TYPE,
        i_interval      IN VARCHAR2,
        i_dosage        IN drug_presc_det.dosage%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        --        i_vacc_med_ext       IN drug_presc_plan.id_vacc_med_ext%TYPE,
        i_id_drug            IN drug_presc_det.id_drug%TYPE,
        i_id_vacc            IN vacc.id_vacc%TYPE DEFAULT NULL,
        i_flg_advers_react   IN VARCHAR2, --NUMBER,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        i_application_spot   IN drug_presc_plan.application_spot%TYPE,
        i_lot_number         IN drug_presc_plan.lot_number%TYPE,
        --i_dt_expiration      IN drug_presc_plan.dt_expiration%TYPE,
        i_dt_exp              IN VARCHAR2,
        i_dos_comp            IN mi_med.qt_dos_comp%TYPE,
        i_unit_measure        IN mi_med.id_unit_measure%TYPE,
        i_dt_predicted        IN VARCHAR2,
        i_test                IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE,
        i_flg_type_date       IN VARCHAR2,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        o_drug_presc_plan     OUT NUMBER,
        o_drug_presc_det      OUT NUMBER,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_result          OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_type_admin          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    *  Criar prescrições de medicamentos (vacinas)
    *
    * @param i_lang                   the id language
    * @param i_episode                id_do episódio
    * @param i_prof                   Profissional que requisita
    * @param i_pat                    id do paciente
    * @param i_flg_time               Realização: E - neste episódio; N - próximo episódio; B - entre episódios
    * @param i_dt_begin               Data a partir da qual é pedida a realização do exame
    * @param i_notes                  Notas de prescrição no plano
    * @param i_take_type              Tipo de plano de tomas: N - normal, S - SOS,  U - unitário, C - contínuo, A - ad eternum
    * @param i_drug                   array de medicamentos
    * @param i_dt_end                 data fim. É indicada em CHECK_PRESC_PARAM; se for 'não aplicável', I_DT_END = NULL
    * @param i_interval               intervalo entre tomas
    * @param i_dosage                 dosagem
    * @param i_prof_cat_type          Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF
    * @param i_justif                 Se a escolha do medicamento foi feita por + frequentes, I_JUSTIF = N. Senão, I_JUSTIF = Y.
    * @param i_justif_valid           Se esta função é chamada a partir do ecrã de justificação, I_JUSTIF_VALID = Y. Senão, I_JUSTIF_VALID = N.
    * @param i_test                   indicação se testa a existência de exames com resultados ou já requisitados (se a msg O_MSG_REQ ou O_MSG_RESULT já foram apresentadas e o user continuou, I_TEST = 'N')
    
    * @param  o_msg_req               mensagem com exames q foram requisitados recentemente
    * @param o_msg_result             mensagem com exames q foram requisitados recentemente e têm resultado
    * @param o_msg_title              Título da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param  o_button                Botões a mostrar: N - não, R - lido, C - confirmado Tb pode mostrar combinações destes, qd é p/ mostrar + do q 1 botão
    * @param o_justif                 Indicação de q precisa de mostrar o ecrã de justificação: NULL - ñ mostra not NULL - contém o título do ecrã de msg
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/03
    **********************************************************************************************/

    FUNCTION get_age_recommend
    (
        i_lang IN language.id_language%TYPE,
        i_val  IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION create_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cs      IN clinical_service.id_clinical_service%TYPE,
        i_id_patient IN NUMBER,
        o_id_episode OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_dt_begin   IN episode.dt_begin_tstz%TYPE,
        o_id_visit   OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_add
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        i_orig       IN VARCHAR2,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_type_vacc  IN VARCHAR2,
        i_id_reg     IN NUMBER,
        i_flg_status IN VARCHAR2,
        o_val        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *    Mais frequentes para as vacinas fora do PNV V.2.4.2
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    * @param i_type                   tipo : T - Tuberculina, V - Vacinas
    * @param i_button                 tipo : A - Todos, S - Mais frequentes
    *
    * @param o_med_freq_label         label (mais frequentes/todos)
    * @param o_med_sel_label          label  (registos selecionados)
    * @param o_search_label           label  (pesquisa)
    * @param o_med_freq               cursor
    * @param o_error                  error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/12/05
    **********************************************************************************************/

    FUNCTION get_vacc_out_me_freq
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_button         IN VARCHAR2,
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Registar as administrações das vacinas, relatos e provas à tuberculina V.2.4.2
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    * @param i_vacc                   id da vacina
    * @param i_id_patient             id do paciente
    * @param i_id_episode             id do episodio
    * @param i_dt_begin               Data de registo
    * @param i_drug_presc_plan        Id da prescrição
    * @param i_flg_status             Estado da Administração ('A' - Administrado)
    * @param i_flg_orig               Origem ('V' - vacinas, 'T'- Tuberculina, 'R' - relato)
    * @param i_desc_vaccine           descrição da vacina (utilizado para os relatos)
    * @param i_flg_advers_react       Se a administração teve reacções adversas
    * @param i_application_spot       local de aplicação
    * @param i_lot_number             Numero de lote
    * @param i_dt_expiration          Data que expira o medicamento
    * @param i_report_orig            Origem do relato
    * @param i_notes                  Notas
    * @param i_flg_time               Realização: E - neste episódio; N - próximo episódio; B - até ao próximo episódio
    * @param i_takes                  Numero de Tomas
    * @param i_dosage                 Dose
    * @param i_unit_measure           Unidade de medida
    * @param i_dt_presc               Data da prescrição (vacinas fora do PNV - vacina trazida pelo utente)
    * @param i_notes_presc            Notas da Prescrição (vacinas fora do PNV - vacina trazida pelo utente)
    * @param i_prof_presc             Profissional que prescreveu( texto livre vacinas fora do PNV - vacina trazida pelo utente)
    * @param i_test                   Indicação se testa a existência de vacinas administradas ou já requisitadas (se a msg O_MSG_REQ ou O_MSG_RESULT já foram apresentadas e o user continuou, I_TEST = 'N')
    * @param i_prof_cat_type          categoria profissional
    
    * @param o_flg_show               Y - existe msg para mostrar; N - ñ existe
    * @param o_msg                    mensagem com vacinas q foram requisitados recentemente ou que já tinham sido administradas
    * @param o_msg_title              Título da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Botões a mostrar: N - não, R - lido, C - confirmado Tb pode mostrar combinações destes, qd é p/ mostrar + do q 1 botão
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/11/28
    **********************************************************************************************/
    FUNCTION set_pat_vacc_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_vacc                IN table_number,
        i_emb                 IN table_varchar,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_begin_str        IN VARCHAR2,
        i_presc               IN prescription.id_prescription%TYPE,
        i_flg_status          IN pat_vacc_adm.flg_status%TYPE,
        i_flg_orig            IN pat_vacc_adm.flg_orig%TYPE,
        i_desc_vaccine        IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_flg_advers_react    IN VARCHAR2,
        i_notes_advers_react  IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot    IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number          IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str   IN VARCHAR2,
        i_report_orig         IN pat_vacc_adm_det.report_orig%TYPE,
        i_notes               IN pat_vacc_adm_det.notes%TYPE,
        i_flg_time            IN table_varchar,
        i_takes               IN table_number,
        i_dosage              IN table_number,
        i_unit_measure        IN table_number,
        i_dt_presc            IN VARCHAR2,
        i_notes_presc         IN pat_vacc_adm.notes_presc%TYPE,
        i_prof_presc          IN pat_vacc_adm.prof_presc%TYPE,
        i_test                IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_predicted        IN VARCHAR2,
        i_flg_reported        IN VARCHAR2 DEFAULT NULL,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN pat_vacc_adm.flg_type_date%TYPE,
        i_dosage_admin        IN table_number,
        i_dosage_unit_measure IN table_number,
        
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_req    OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_vacc_adm_pfh
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_vacc         IN vacc.id_vacc%TYPE,
        i_dt_begin_str IN VARCHAR2,
        i_desc_vaccine IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_lot_number   IN pat_vacc_adm_det.lot_number%TYPE,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION set_pat_vacc_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_vacc                IN table_number,
        i_emb                 IN table_varchar,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_begin_str        IN VARCHAR2,
        i_presc               IN prescription.id_prescription%TYPE,
        i_flg_status          IN pat_vacc_adm.flg_status%TYPE,
        i_flg_orig            IN pat_vacc_adm.flg_orig%TYPE,
        i_desc_vaccine        IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_flg_advers_react    IN VARCHAR2,
        i_notes_advers_react  IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot    IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number          IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str   IN VARCHAR2,
        i_report_orig         IN pat_vacc_adm_det.report_orig%TYPE,
        i_notes               IN pat_vacc_adm_det.notes%TYPE,
        i_flg_time            IN table_varchar,
        i_takes               IN table_number,
        i_dosage              IN table_number,
        i_unit_measure        IN table_number,
        i_dt_presc            IN VARCHAR2,
        i_notes_presc         IN pat_vacc_adm.notes_presc%TYPE,
        i_prof_presc          IN pat_vacc_adm.prof_presc%TYPE,
        i_test                IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_predicted        IN VARCHAR2,
        i_flg_reported        IN VARCHAR2 DEFAULT NULL,
        i_id_drug             IN table_varchar,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN pat_vacc_adm.flg_type_date%TYPE,
        i_dosage_admin        IN table_number,
        i_dosage_unit_measure IN table_number,
        
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_req    OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION set_pat_report
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_presc         IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_dt_begin_str  IN VARCHAR2 DEFAULT '',
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN mi_med.id_drug%TYPE,
        i_vacc          IN pat_vacc_adm.id_vacc%TYPE,
        
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE DEFAULT NULL,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE DEFAULT '',
        
        i_application_spot_code IN pat_vacc_adm_det.application_spot_code%TYPE DEFAULT NULL,
        i_application_spot      IN pat_vacc_adm_det.application_spot%TYPE DEFAULT '',
        
        i_lot_number        IN pat_vacc_adm_det.lot_number%TYPE DEFAULT '',
        i_dt_expiration_str IN VARCHAR2 DEFAULT '',
        
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        i_vacc_manuf_desc IN VARCHAR2 DEFAULT '',
        
        i_dosage_admin        IN pat_vacc_adm.dosage_admin%TYPE DEFAULT NULL,
        i_dosage_unit_measure IN pat_vacc_adm.dosage_unit_measure%TYPE DEFAULT NULL,
        
        i_adm_route IN VARCHAR2 DEFAULT '',
        
        i_vacc_origin      IN pat_vacc_adm_det.id_vacc_origin%TYPE DEFAULT NULL,
        i_vacc_origin_desc IN VARCHAR2 DEFAULT '',
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE DEFAULT NULL,
        i_doc_vis_desc IN VARCHAR2 DEFAULT '',
        
        i_dt_doc_delivery     IN VARCHAR2 DEFAULT '',
        i_vacc_funding_cat    IN pat_vacc_adm_det.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source IN pat_vacc_adm_det.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc IN pat_vacc_adm_det.funding_source_desc%TYPE DEFAULT NULL,
        
        i_information_source IN pat_vacc_adm_det.id_information_source%TYPE DEFAULT '',
        i_report_orig        IN pat_vacc_adm_det.report_orig%TYPE DEFAULT '',
        
        i_administred      IN pat_vacc_adm_det.id_administred%TYPE DEFAULT NULL,
        i_administred_desc IN VARCHAR2 DEFAULT '',
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2 DEFAULT '',
        
        i_notes IN pat_vacc_adm_det.notes%TYPE DEFAULT '',
        
        i_flg_status      IN pat_vacc_adm_det.flg_status%TYPE DEFAULT 'A',
        i_suspended_notes IN pat_vacc_adm_det.suspended_notes%TYPE DEFAULT '',
        i_id_reason_sus   IN pat_vacc_adm_det.id_reason_sus%TYPE DEFAULT NULL,
        i_dt_suspended    IN pat_vacc_adm_det.dt_suspended%TYPE DEFAULT NULL,
        
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *   Alterar o estado da req (detalhe) de vacina:  requisitado => finalizado V.2.4.2
    *
    * @param i_lang                   The id language
    * @param i_vacc_adm_det           Id da requisicao de vacina
    * @param i_patient                Id do paciente
    * @param i_notes                  Notas (null FFR)
    * @param i_flg_take_type          Tipo de toma (null FFR)
    * @param i_prof                   Id_profissional
    * @param i_prof_cat_type          Categoria profiaaional
    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2008/01/09
    **********************************************************************************************/

    FUNCTION set_vacc_presc_det
    (
        i_lang               IN language.id_language%TYPE,
        i_vacc_adm           IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_notes              IN pat_vacc_adm_det.notes%TYPE,
        i_flg_take_type      IN VARCHAR2,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_flg_advers_react   IN VARCHAR2,
        i_notes_advers_react IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot   IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number         IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str  IN VARCHAR2,
        i_dt_adm_str         IN VARCHAR2,
        i_vacc_manuf         IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        code_mvx             IN vacc_manufacturer.code_mvx%TYPE,
        i_flg_type_date      IN pat_vacc_adm_det.flg_type_date%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_evaluation_values
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --
    --Constantes do package
    --
    /*Constante com o código para a lable da primeira coluna do quadro de vacinas mais frequentes*/
    vacc_more_freq_header_col1 CONSTANT VARCHAR2(20) := 'VACC_LABEL_001';
    /*Constante com o código para a lable da segunda coluna do quadro de vacinas mais frequentes*/
    vacc_more_freq_header_col2 CONSTANT VARCHAR2(20) := 'VACC_LABEL_002';

    --
    --Variáveis globais do package
    --
    g_found BOOLEAN;
    g_error VARCHAR2(2000);
    --
    g_months_sign VARCHAR2(200);
    g_days_sign   VARCHAR2(200);
    --

    --
    g_sysdate        DATE;
    g_sysdate_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
    g_dt_next        DATE;
    g_presc_det_pend drug_presc_det.flg_status%TYPE;
    g_presc_det_exe  drug_presc_det.flg_status%TYPE;

    --

    g_flg_time_betw drug_prescription.flg_time%TYPE;

    g_drug_interv interv_drug.flg_type%TYPE;

    --Episode Status
    g_episode_active_status episode.flg_status%TYPE;

    --
    g_prescription_flg_type_e prescription.flg_type%TYPE;
    g_prescription_flg_type_i prescription.flg_type%TYPE;
    g_prescription_flg_type_a prescription.flg_type%TYPE;

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

    /*g_selected VARCHAR2(1);
    g_flg_pesq VARCHAR2(1);*/
    /*
     * =================================
     * -- Tuberculin developement
     * =================================
    */
    FUNCTION get_value_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_key     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_year_from_timestamp(i_dt TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR;

    FUNCTION get_month_year_from_timestamp
    (
        i_lang IN language.id_language%TYPE,
        i_dt   TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR;

    FUNCTION get_tuberculin_local_med_freq
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_button IN VARCHAR2,
        --OUT
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_tests_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        -- Adverses React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_test_add
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        --OUT
        o_main_title OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_test_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --OUT
        o_group_name      OUT VARCHAR2,
        o_tuberculin_time OUT pk_types.cursor_type,
        o_tuberculin_par  OUT pk_types.cursor_type,
        o_tuberculin_val  OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_tuberculin_test_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_drug         IN drug_presc_det.id_drug%TYPE, --mi_med.id_drug%TYPE,
        i_dosage       IN drug_presc_det.dosage_description%TYPE,
        i_unit_measure IN drug_presc_det.id_unit_measure%TYPE,
        i_admin_via    IN drug_presc_det.route_id%TYPE,
        --
        i_prof_write          IN professional.id_professional%TYPE,
        i_notes_justif        IN drug_presc_det.notes_justif%TYPE,
        i_notes               IN drug_presc_det.notes%TYPE,
        i_presc_date          IN VARCHAR2,
        i_requested_by        IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --OUT
        o_test_id    OUT drug_prescription.id_drug_prescription%TYPE,
        o_id_admin   OUT drug_presc_plan.id_drug_presc_plan%TYPE,
        o_type_admin OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_tuberculin_test_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_test_id             IN NUMBER,
        i_dt_adm              IN VARCHAR2,
        i_lote_adm            IN VARCHAR2,
        i_dt_valid            IN VARCHAR2,
        i_app_place           IN VARCHAR2,
        i_prof_write          professional.id_professional%TYPE,
        i_notes               IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_tuberculin_test_res
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_test_id       IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_read       IN VARCHAR2,
        i_value         IN drug_presc_result.value%TYPE,
        i_evaluation    IN drug_presc_result.evaluation%TYPE,
        i_evaluation_id IN drug_presc_result.id_evaluation%TYPE,
        i_reactions     IN drug_presc_result.notes_advers_react%TYPE,
        i_prof_write    IN professional.id_professional%TYPE,
        i_notes         IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cancel_info
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_cancel_id IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op IN VARCHAR,
        --Out
        o_main_title  OUT VARCHAR2,
        o_notes_title OUT VARCHAR2,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_info
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --presc_det
        i_cancel_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op    IN VARCHAR,
        i_notes_cancel IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_value_icon
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2,
        i_result  IN drug_presc_result.id_evaluation%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_summary_value_label
    (
        i_lang      IN language.id_language%TYPE,
        i_minutes   IN VARCHAR2,
        i_hours     IN VARCHAR2,
        i_days      IN VARCHAR2,
        i_state     IN VARCHAR2,
        i_dt_cancel IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_value     IN drug_presc_result.value%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_summary_state_label
    (
        i_lang  IN language.id_language%TYPE,
        i_state VARCHAR2
    ) RETURN VARCHAR;

    FUNCTION get_summary_value_bg_color
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2
    ) RETURN VARCHAR;

    FUNCTION get_summary_value_icon_color
    (
        i_minutes IN VARCHAR2,
        i_hours   IN VARCHAR2,
        i_days    IN VARCHAR2,
        i_state   IN VARCHAR2
    ) RETURN VARCHAR;

    FUNCTION get_summary_time_min
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_summary_time_hour
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_summary_time_day
    (
        i_current_dt TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt         TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_tuberculin_test_timestamp
    (
        i_dt_presc  TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_take   TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_result TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_tuberculin_test_state
    (
        i_dt_presc  TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_take   TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_result TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_cancel TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_tuberculin_test_state(i_test_id IN drug_prescription.id_drug_prescription%TYPE) RETURN VARCHAR2;

    FUNCTION format_tuberculin_test_date
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_type_date IN VARCHAR2
    ) RETURN VARCHAR;

    g_tuberculin_test_state_presc CONSTANT VARCHAR2(1) := 'P';
    g_tuberculin_test_state_adm   CONSTANT VARCHAR2(1) := 'A';
    g_tuberculin_test_state_res   CONSTANT VARCHAR2(1) := 'R';
    g_tuberculin_test_state_canc  CONSTANT VARCHAR2(1) := 'C';
    --identifica o grupo das tuberculinas
    --TODO: Este valor deve ser parametrizado
    g_tuberculin_default_dci_id CONSTANT mi_med.dci_id%TYPE := 12156;

    /*
     * =================================
     * -- End of tuberculin developement
     * =================================
    */
    /************************************************************************************************************
    * Esta função retorna os conteudos para os mais frequentes e para a lupa + das Vacinas fora do PNV (Plano Nacional de Vacinação)
    e para as provas à tuberculina
    *
    * @param      i_lang               language
    * @param      i_prof               profissional
    * @param      i_type               tipo : T - Tuberculina, V - Vacinas
    * @param      i_button             tipo : A - Todos, S - Mais frequentes
    *
    * @param      o_med_freq_label     label (mais frequentes/todos)
    * @param      o_med_sel_label      label  (registos selecionados)
    * @param      o_search_label       label  (pesquisa)
    * @param      o_med_freq           cursor
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2007/12/05
    ***********************************************************************************************************/

    FUNCTION get_most_freq_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_type           IN VARCHAR2,
        i_button         IN VARCHAR2,
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    g_flg_orig_v VARCHAR(1);
    g_flg_orig_r VARCHAR(1);
    /*
     * =================================
     * -- Vaccines developement
     * =================================
    */

    FUNCTION count_vacc_take
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_lasttake IN drug_presc_plan.dt_take_tstz%TYPE,
        i_prof     IN profissional
    ) RETURN NUMBER;

    FUNCTION get_last_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_vacc_summary
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_group_name   OUT VARCHAR2,
        o_vaccine_time OUT pk_types.cursor_type,
        o_vaccine_par  OUT pk_types.cursor_type,
        o_vaccine_val  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_other_vacc_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        o_group_name OUT VARCHAR2,
        o_vacc_time  OUT pk_types.cursor_type,
        o_vacc_par   OUT pk_types.cursor_type,
        o_vacc_val   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_summary_all
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        --OUT
        o_vacc_header_title    OUT VARCHAR2,
        o_vacc_header_subtitle OUT VARCHAR2,
        --Other Vaccines (outside PNV)
        o_oth_vaccine_group_name OUT VARCHAR2,
        o_oth_vaccine_time       OUT pk_types.cursor_type,
        o_oth_vaccine_par        OUT pk_types.cursor_type,
        o_oth_vaccine_val        OUT pk_types.cursor_type,
        --PNV Vaccines
        o_vaccine_group_name OUT VARCHAR2,
        o_vaccine_time       OUT pk_types.cursor_type,
        o_vaccine_par        OUT pk_types.cursor_type,
        o_vaccine_val        OUT pk_types.cursor_type,
        --Tuberculin tests
        o_tuberculin_group_name OUT VARCHAR2,
        o_tuberculin_time       OUT pk_types.cursor_type,
        o_tuberculin_par        OUT pk_types.cursor_type,
        o_tuberculin_val        OUT pk_types.cursor_type,
        o_create                OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE validate_input_parameters
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    );

    g_vacc_icon_green CONSTANT VARCHAR2(10) := 'N|G|X';
    g_vacc_icon_red   CONSTANT VARCHAR2(10) := 'N|R|X';
    g_vacc_icon_check CONSTANT VARCHAR2(15) := 'Y|X|CheckIcon';

    g_error_message_20001 CONSTANT VARCHAR2(100) := 'INVALID_INPUT_PARAMETERS';
    g_error_message_20002 CONSTANT VARCHAR2(100) := 'CANNOT_INSERT_DATA_IN_TABLE';
    g_error_message_20003 CONSTANT VARCHAR2(100) := 'CANNOT_UPDATE_DATA_IN_TABLE';

    --parametrização
    g_tuberculin_test_id CONSTANT NUMBER(2) := 18;

    /*
     * =================================
     * -- End of vaccines developement
     * =================================
    */

    /*
     * =================================
     * -- DML procedures
     * =================================
    */
    /*    FUNCTION ins_drug_prescription
    (
        id_episode_in                IN drug_prescription.id_episode%TYPE DEFAULT NULL,
        id_professional_in           IN drug_prescription.id_professional%TYPE DEFAULT NULL,
        flg_type_in                  IN drug_prescription.flg_type%TYPE DEFAULT NULL,
        barcode_in                   IN drug_prescription.barcode%TYPE DEFAULT NULL,
        num_days_expire_in           IN drug_prescription.num_days_expire%TYPE DEFAULT NULL,
        flg_time_in                  IN drug_prescription.flg_time%TYPE DEFAULT NULL,
        flg_status_in                IN drug_prescription.flg_status%TYPE DEFAULT NULL,
        id_prof_cancel_in            IN drug_prescription.id_prof_cancel%TYPE DEFAULT NULL,
        notes_cancel_in              IN drug_prescription.notes_cancel%TYPE DEFAULT NULL,
        id_episode_origin_in         IN drug_prescription.id_episode_origin%TYPE DEFAULT NULL,
        id_episode_destination_in    IN drug_prescription.id_episode_destination%TYPE DEFAULT NULL,
        id_protocols_in              IN drug_prescription.id_protocols%TYPE DEFAULT NULL,
        id_prev_episode_in           IN drug_prescription.id_prev_episode%TYPE DEFAULT NULL,
        dt_drug_prescription_tstz_in IN drug_prescription.dt_drug_prescription_tstz%TYPE DEFAULT NULL,
        dt_begin_tstz_in             IN drug_prescription.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_in            IN drug_prescription.dt_cancel_tstz%TYPE DEFAULT NULL,
        id_patient_in                IN drug_prescription.id_patient%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER;*/

    FUNCTION ins_drug_presc_det
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        id_drug_prescription_in  IN drug_presc_det.id_drug_prescription%TYPE,
        notes_in                 IN drug_presc_det.notes%TYPE,
        flg_take_type_in         IN drug_presc_det.flg_take_type%TYPE,
        qty_in                   IN drug_presc_det.qty%TYPE,
        rate_in                  IN drug_presc_det.rate%TYPE,
        flg_status_in            IN drug_presc_det.flg_status%TYPE,
        id_prof_cancel_in        IN drug_presc_det.id_prof_cancel%TYPE,
        notes_cancel_in          IN drug_presc_det.notes_cancel%TYPE,
        notes_justif_in          IN drug_presc_det.notes_justif%TYPE,
        interval_in              IN drug_presc_det.interval%TYPE,
        takes_in                 IN drug_presc_det.takes%TYPE,
        dosage_in                IN drug_presc_det.dosage%TYPE,
        value_bolus_in           IN drug_presc_det.value_bolus%TYPE,
        value_drip_in            IN drug_presc_det.value_drip%TYPE,
        dosage_description_in    IN drug_presc_det.dosage_description%TYPE,
        flg_ci_in                IN drug_presc_det.flg_ci%TYPE,
        flg_cheaper_in           IN drug_presc_det.flg_cheaper%TYPE,
        flg_justif_in            IN drug_presc_det.flg_justif%TYPE,
        flg_attention_in         IN drug_presc_det.flg_attention%TYPE,
        flg_attention_print_in   IN drug_presc_det.flg_attention_print%TYPE,
        id_drug_despachos_in     IN drug_presc_det.id_drug_despachos%TYPE,
        id_unit_measure_bolus_in IN drug_presc_det.id_unit_measure_bolus%TYPE,
        id_unit_measure_drip_in  IN drug_presc_det.id_unit_measure_drip%TYPE,
        id_unit_measure_in       IN drug_presc_det.id_unit_measure%TYPE,
        dt_begin_tstz_in         IN drug_presc_det.dt_begin_tstz%TYPE,
        dt_end_tstz_in           IN drug_presc_det.dt_end_tstz%TYPE,
        dt_cancel_tstz_in        IN drug_presc_det.dt_cancel_tstz%TYPE,
        dt_end_presc_tstz_in     IN drug_presc_det.dt_end_presc_tstz%TYPE,
        dt_end_bottle_tstz_in    IN drug_presc_det.dt_end_bottle_tstz%TYPE,
        dt_order_in              IN drug_presc_det.dt_order%TYPE,
        id_prof_order_in         IN drug_presc_det.id_prof_order%TYPE,
        id_order_type_in         IN drug_presc_det.id_order_type%TYPE,
        flg_co_sign_in           IN drug_presc_det.flg_co_sign%TYPE,
        dt_co_sign_in            IN drug_presc_det.dt_co_sign%TYPE,
        notes_co_sign_in         IN drug_presc_det.notes_co_sign%TYPE,
        id_prof_co_sign_in       IN drug_presc_det.id_prof_co_sign%TYPE,
        frequency_in             IN drug_presc_det.frequency%TYPE,
        id_unit_measure_freq_in  IN drug_presc_det.id_unit_measure_freq%TYPE,
        duration_in              IN drug_presc_det.duration%TYPE,
        id_unit_measure_dur_in   IN drug_presc_det.id_unit_measure_dur%TYPE,
        dt_start_presc_tstz_in   IN drug_presc_det.dt_start_presc_tstz%TYPE,
        refill_in                IN drug_presc_det.refill%TYPE,
        qty_inst_in              IN drug_presc_det.qty_inst%TYPE,
        unit_measure_inst_in     IN drug_presc_det.unit_measure_inst%TYPE,
        id_drug_in               IN drug_presc_det.id_drug%TYPE,
        vers_in                  IN drug_presc_det.vers%TYPE,
        route_id_in              IN drug_presc_det.route_id%TYPE,
        id_justification_in      IN drug_presc_det.id_justification%TYPE,
        flg_interac_med_in       IN drug_presc_det.flg_interac_med%TYPE,
        flg_interac_allergy_in   IN drug_presc_det.flg_interac_allergy%TYPE,
        i_vacc_manuf             IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        code_mvx                 IN vacc_manufacturer.code_mvx%TYPE
    ) RETURN PLS_INTEGER;

    FUNCTION ins_drug_presc_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        id_drug_presc_det_in     IN drug_presc_plan.id_drug_presc_det%TYPE,
        id_drug_take_time_in     IN drug_presc_plan.id_drug_take_time%TYPE,
        id_prof_writes_in        IN drug_presc_plan.id_prof_writes%TYPE,
        dosage_in                IN drug_presc_plan.dosage%TYPE,
        flg_status_in            IN drug_presc_plan.flg_status%TYPE,
        notes_in                 IN drug_presc_plan.notes%TYPE,
        id_prof_cancel_in        IN drug_presc_plan.id_prof_cancel%TYPE,
        notes_cancel_in          IN drug_presc_plan.notes_cancel%TYPE,
        id_episode_in            IN drug_presc_plan.id_episode%TYPE,
        rate_in                  IN drug_presc_plan.rate%TYPE,
        dosage_exec_in           IN drug_presc_plan.dosage_exec%TYPE,
        flg_advers_react_in      IN drug_presc_plan.flg_advers_react%TYPE,
        notes_advers_react_in    IN drug_presc_plan.notes_advers_react%TYPE,
        application_spot_in      IN drug_presc_plan.application_spot%TYPE,
        lot_number_in            IN drug_presc_plan.lot_number%TYPE,
        dt_expiration_in         IN drug_presc_plan.dt_expiration%TYPE,
        id_vacc_med_ext_in       IN drug_presc_plan.id_vacc_med_ext%TYPE,
        dt_plan_tstz_in          IN drug_presc_plan.dt_plan_tstz%TYPE,
        dt_take_tstz_in          IN drug_presc_plan.dt_take_tstz%TYPE,
        dt_cancel_tstz_in        IN drug_presc_plan.dt_cancel_tstz%TYPE,
        dt_next_take_in          IN TIMESTAMP WITH LOCAL TIME ZONE,
        flg_type_date_in         IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin_in        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure_in IN drug_presc_plan.dosage_unit_measure%TYPE,
        i_vacc_funding_cat_in    IN drug_presc_plan.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source_in IN drug_presc_plan.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc_in IN drug_presc_plan.funding_source_desc%TYPE DEFAULT NULL,
        i_vacc_doc_vis_in        IN drug_presc_plan.id_vacc_doc_vis%TYPE DEFAULT NULL,
        i_vacc_doc_vis_str       IN drug_presc_plan.doc_vis_desc%TYPE DEFAULT '',
        i_vacc_origin_in         IN drug_presc_plan.id_vacc_origin%TYPE DEFAULT NULL,
        i_origin_desc_in         IN drug_presc_plan.origin_desc%TYPE DEFAULT '',
        i_ordered_desc_in        IN drug_presc_plan.ordered_desc%TYPE DEFAULT '',
        i_administred_desc_in    IN drug_presc_plan.administred_desc%TYPE DEFAULT '',
        i_vacc_route_in          IN drug_presc_plan.vacc_route_data%TYPE DEFAULT '',
        i_ordered_in             IN drug_presc_plan.id_ordered%TYPE DEFAULT NULL,
        i_administred_in         IN drug_presc_plan.id_administred%TYPE DEFAULT NULL,
        dt_doc_delivery_in       IN drug_presc_plan.dt_doc_delivery_tstz%TYPE DEFAULT NULL,
        i_vacc_adv_reaction_in   IN drug_presc_plan.id_vacc_adv_reaction%TYPE DEFAULT NULL,
        i_application_spot_in    IN drug_presc_plan.application_spot_code%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER;

    FUNCTION ins_drug_presc_result
    (
        i_prof                  IN profissional,
        id_drug_presc_plan_in   IN drug_presc_result.id_drug_presc_plan%TYPE,
        dt_drug_presc_result_in IN drug_presc_result.dt_drug_presc_result%TYPE,
        value_in                IN drug_presc_result.value%TYPE,
        evaluation_in           IN drug_presc_result.evaluation%TYPE,
        evaluation_id_in        IN drug_presc_result.id_evaluation%TYPE,
        notes_advers_react_in   IN drug_presc_result.notes_advers_react%TYPE,
        id_prof_resp_in         IN drug_presc_result.id_prof_resp%TYPE,
        notes_in                IN drug_presc_result.notes%TYPE,
        adw_last_update_in      IN drug_presc_result.adw_last_update%TYPE
    ) RETURN PLS_INTEGER;

    PROCEDURE upd_drug_presc_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        id_drug_presc_plan_in IN drug_presc_plan.id_drug_presc_plan%TYPE,
        id_drug_presc_det_in  IN drug_presc_plan.id_drug_presc_det%TYPE,
        id_drug_take_time_in  IN drug_presc_plan.id_drug_take_time%TYPE,
        id_prof_writes_in     IN drug_presc_plan.id_prof_writes%TYPE,
        dosage_in             IN drug_presc_plan.dosage%TYPE,
        flg_status_in         IN drug_presc_plan.flg_status%TYPE,
        notes_in              IN drug_presc_plan.notes%TYPE,
        id_prof_cancel_in     IN drug_presc_plan.id_prof_cancel%TYPE,
        notes_cancel_in       IN drug_presc_plan.notes_cancel%TYPE,
        id_episode_in         IN drug_presc_plan.id_episode%TYPE,
        rate_in               IN drug_presc_plan.rate%TYPE,
        dosage_exec_in        IN drug_presc_plan.dosage_exec%TYPE,
        flg_advers_react_in   IN drug_presc_plan.flg_advers_react%TYPE,
        notes_advers_react_in IN drug_presc_plan.notes_advers_react%TYPE,
        application_spot_in   IN drug_presc_plan.application_spot%TYPE,
        lot_number_in         IN drug_presc_plan.lot_number%TYPE,
        dt_expiration_in      IN drug_presc_plan.dt_expiration%TYPE,
        id_vacc_med_ext_in    IN drug_presc_plan.id_vacc_med_ext%TYPE,
        dt_plan_tstz_in       IN drug_presc_plan.dt_plan_tstz%TYPE,
        dt_take_tstz_in       IN drug_presc_plan.dt_take_tstz%TYPE,
        dt_cancel_tstz_in     IN drug_presc_plan.dt_cancel_tstz%TYPE,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE
    );

    /*
     * =================================
     * -- END of DML procedures
     * =================================
    */

    FUNCTION get_vacc_dose_info_detail_new
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_emb      IN me_med.emb_id%TYPE,
        o_info     OUT pk_types.cursor_type,
        o_info_age OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_last_take_icon(i_dt IN drug_presc_plan.dt_plan_tstz%TYPE) RETURN VARCHAR2;

    FUNCTION get_adm_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_resp_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Informação sobre a medicação (ecrã de administração)
    *
    * @param i_lang                language id
    * @param i_prof                array do profissional
    * @param i_emb                id_do medicamento
    * @param i_med                'E' Externo , 'I' Interno
    *
    * @return                      Nome do medicamento
    *
    * @author                      Teresa Coutinho
    * @version                     1.0
    * @since                       2008/01/08
    **********************************************************************************************/

    FUNCTION get_med_descr
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_emb       IN me_med.emb_id%TYPE,
        i_med       IN VARCHAR2,
        o_med_descr OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION exist_pat_vacc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_vacc       IN table_number,
        i_emb        IN table_varchar,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_req    OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_adm_rep_intf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_adm IN pat_vacc_adm_det.id_pat_vacc_adm_det%TYPE,
        --OUT
        o_adm_det OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_test_warnings
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_test_id IN drug_prescription.id_drug_prescription%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_adm_warnings
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
     * =================================
     * -- Vaccines details
     * =================================
    */
    FUNCTION get_oth_vacc_value_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc_take_id IN NUMBER,
        i_key          IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_vacc_value_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc_take_id IN NUMBER,
        i_key          IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_vaccines_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_vacc_id IN vacc.id_vacc%TYPE,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        o_vacc_name          OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --Advers React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /*
     * =================================
     * -- Vaccines details End
     * =================================
    */

    FUNCTION exist_imp_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_presc      IN prescription.id_prescription%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_req    OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * Return the TIMESTAMP as a string in the correct format
    *
    * @param      i_lang               language
    * @param      i_prof               profissional
    * @param      i_date               TIMESTAMP
    *
    * @return     a string with the date in the the correct format
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/02/27
    ***********************************************************************************************************/
    FUNCTION format_dt_expiration_test_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR;

    FUNCTION get_reading_unit_list
    (
        i_lang      IN language.id_language%TYPE,
        o_read_unit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE upd_drug_presc_det
    (
        id_drug_presc_det_in IN drug_presc_det.id_drug_presc_det%TYPE,
        i_vacc_manufacturer  IN drug_presc_det.id_vacc_manufacturer%TYPE,
        code_mvx             IN drug_presc_det.code_mvx%TYPE
    );

    /************************************************************************************************************
    * Cancel the reported vaccine prescription
    *
    * @param      i_lang               language
    * @param      i_episode            episode
    * @param      i_id_patient         patient
    * @param      i_prof               profissional
    * @param      id_id_pat_medication_list  id_pat_medication_list
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/03/20
    ***********************************************************************************************************/
    FUNCTION set_cancel_report_vacc
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_prof                    IN profissional,
        id_id_pat_medication_list IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * GET PNV vaccines
    *
    * @param      i_lang               language
    * @param      i_id_patient         patient
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/07
    ***********************************************************************************************************/

    FUNCTION get_vacc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_vaccine    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Add PNV vaccines
    *
    * @param      i_lang               language
    * @param      i_id_patient         patient
    * @param      i_vacc        array id_vacc
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/07
    ***********************************************************************************************************/

    FUNCTION ins_vacc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_vacc       IN table_number,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Validates the hided values and returns the warings when existing
    *
    * @param      i_lang               language
    * @param      i_prof               professional
    * @param      i_val                code 'OV'/'OP'
    * @param      i_vacc               id_vacc
    * @param      i_patient            id_patient
    *
    * @param      o_flg_show         flag that indicates if exist any warning message to be shown
    * @param      o_message_title    label for the title of the warning message screen
    * @param      o_message_text     warning message
    * @param      o_forward_button   label for the forward button
    * @param      o_back_button      label for the back button
    * @param      o_error            error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Teresa Coutinho V.2.4.3
    * @version    0.1
    * @since      2008/04/07
    ***********************************************************************************************************/

    FUNCTION get_vacc_warnings
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_val        IN sys_domain.val%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_group_available
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_presc_type IN vacc_type_group.flg_presc_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION count_vacc_take_all
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE,
        i_prof   IN profissional
    ) RETURN NUMBER;

    /************************************************************************************************************
    * This function returns the administration details for the specified vaccine take, if any, or else
    * the administration details for all vaccines for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/

    FUNCTION get_vacc_presc_det
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_vacc_id      IN vacc.id_vacc%TYPE,
        i_vacc_take_id IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_to_add       IN BOOLEAN,
        o_presc_title  OUT VARCHAR2,
        o_presc_det    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the result details for the specified tuberculin test if any or else
    * the result details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_res_title        title for the prescription details
    * @param      o_res_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_res_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Returns the date of the last administration for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_id_pat             patient's ID
    * @param      i_vacc               vaccine's ID
    *
    * @return     date for the last vaccine administration
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/04/28
    ***********************************************************************************************************/
    FUNCTION get_next_take_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        i_vacc   IN vacc.id_vacc%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /************************************************************************************************************
    * This function returns a string with the day and month(abbreviation) separated by a space,
    *  for a specified TIMESTAMP (e.g. 12 Nov)
    *
    * @param      i_lang           language
    * @param      i_dt             date as a timestamp
    * @param      i_prof           professional
    *
    * @return     day and month(abbreviation) as a string
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/05/14
    ***********************************************************************************************************/
    FUNCTION get_day_month_from_timestamp
    (
        i_lang IN language.id_language%TYPE,
        i_dt   TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /************************************************************************************************************
    * This function returns the administration details for the specified tuberculin test if any or else
    * the administration details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_adm_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_advers_react_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the administration details for the specified vaccine take, if any, or else
    * the administration details for all vaccines for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_vacc_adm_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT p_adm_det_cur,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the prescription details for the specified tuberculin test if any or else
    * the prescription details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_patient            patient's ID
    * @param      i_prof               profisisonal
    * @param      i_test_id            tuberculin test ID
    * @param      i_to_add             if is to be used in screens that allows to add information
    *
    * @param      o_presc_title        title for the prescription details
    * @param      o_presc_det          cursor with the prescription details information
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes [OA]
    * @version    0.1
    * @since      2007/11/23
    ***********************************************************************************************************/
    FUNCTION get_tuberculin_test_presc_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the adverse reaction 
    * details for all tuberculin test for the patient
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    *
    * @param      o_adm_title        title for the prescription details
    * @param      o_adm_det          cursor with
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Rita Lopes
    * @version    0.1
    * @since      2011/03/28
    ***********************************************************************************************************/
    FUNCTION get_tub_advers_react_det
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        i_to_add  IN BOOLEAN,
        --OUT
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the ordinality of a dose
    *
    * @param      n_dose           dose
    * @param      i_lang           language
    *
    * @return     string
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/11/04
    ***********************************************************************************************************/

    FUNCTION vacc_ordinal
    (
        n_dose IN NUMBER,
        i_lang IN language.id_language%TYPE
    ) RETURN VARCHAR2;

    --------------------------------------------------------------------------------

    FUNCTION get_care_dash_vacc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_vacc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolve o id do grupo de vacinas associado ao tipo que é passado na entrada
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_flg_presc_type  Tipo de prescrição, se é vacina PNV, outras vacinas e provas de tuberculina
    
    * @param OUT  o_type_group      id_vacc_type_group do tipo de vacinas que é passado
    *
    * @author                   Pedro Teixeira
    * @since                    27/04/2009
    ********************************************************************************************/
    FUNCTION get_vacc_type_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_presc_type IN vacc_type_group.flg_presc_type%TYPE,
        o_type_group     OUT vacc_type_group.id_vacc_type_group%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolve 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_value           Id da prescricao da vacina
    
    * @param OUT  o_advers_react    cursor com a info de reaccoes adversas
    *
    * @author                   Pedro Teixeira
    * @since                    27/04/2009
    ********************************************************************************************/
    FUNCTION get_advers_react
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN NUMBER,
        i_type_vacc IN VARCHAR2,
        o_id_value  OUT NUMBER,
        o_notes     OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function return a value of adverse reaction
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_value           Vacc prescription identifier
    * @param IN   i_type_vacc       Vacc Type of the vaccine (V- Administer, R - Report)
    *
    * @return Adverse reaction value
    *
    * @author                   Jorge Silva
    * @since                    12/05/2014
    ********************************************************************************************/
    FUNCTION get_advers_react_value
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN NUMBER,
        i_type_vacc IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION set_advers_react_internal
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_reg    IN drug_prescription.id_drug_prescription%TYPE,
        i_value     IN vacc_advers_react.id_vacc_adver_reac%TYPE,
        i_notes     IN vacc_advers_react.notes_advers_react%TYPE,
        i_type_vacc IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_advers_react
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_reg    IN drug_prescription.id_drug_prescription%TYPE,
        i_value     IN vacc_advers_react.id_vacc_adver_reac%TYPE,
        i_notes     IN vacc_advers_react.notes_advers_react%TYPE,
        i_type_vacc IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return all manufacturer data
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_manufacturer    all manufacturer 
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_drug           IN mi_med.id_drug%TYPE,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets list of reported options
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids 
    * @param   O_DOMAINS the cursor with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Rita Lopes
    * @version 1.0 
    * @since   19-05-2011
    */
    FUNCTION get_reported
    (
        i_lang    IN sys_domain.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_adm_det_intf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_adm IN pat_vacc_adm_det.id_pat_vacc_adm_det%TYPE,
        --OUT
        o_adm_det OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_drug_adm_intf
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_adm IN pat_vacc_adm_det.id_pat_vacc_adm_det%TYPE,
        --OUT
        o_adm_det OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_unit_measure
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_unit_measure OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_rep
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_filter  IN VARCHAR2,
        o_vacc        OUT pk_types.cursor_type,
        o_hist        OUT pk_types.cursor_type,
        o_discontinue OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_filter IN VARCHAR2,
        o_vacc       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vaccines_detail_free_text
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_reg     IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        o_vacc_name          OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --Advers React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the list of vaccine per patient
     * and return: - vaccine codes      
     *
     * DEPENDENCIES: REPORTS
     *
     * @param  i_lang  IN                      Language ID
     * @param  i_prof  IN                      Professional structure
     * @param  i_patient  IN                   Patient ID
     * @param  i_id_scope  IN                  Scope ID
     * @param  i_scope  OUT                    Scope
     *
     * @return   BOOLEAN
     *
     * @version  2.6.3.5
     * @since    31-Mar-2014
     * @author   Joel Lopes
    */
    FUNCTION get_vacc_list_cda
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_id_scope IN NUMBER,
        i_scope    IN VARCHAR2
    ) RETURN t_tab_vacc_cdas;

    /**
     * This function returned a date of next take     
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient ID
     * @param  i_vacc          IN   Vacc ID
     * @param  i_dt_adm_str    IN   Date Administration
     * 
     * @param  o_info_next_date  OUT Cursor of next take date
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_next_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_vacc           IN vacc.id_vacc%TYPE,
        i_dt_adm_str     IN VARCHAR2,
        o_info_next_date OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returned a viewer details    
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_vacc          IN   Vacc ID
     * 
     * @param  o_detail_info_out  OUT Cursor of viewer details
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_viewer_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vacc        IN vacc.id_vacc%TYPE,
        o_detail_info OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function return all values of administration screen create or edit   
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient Identifier
     * @param  i_vacc          IN   Vacc ID
     * @param  i_drug          IN   Prescription drug ID
     * 
     * @param  o_form_out      OUT Cursor of all values of administration screen   
     * @param  o_doc_show      OUT Y/N Show doc in this screen
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_form_administration
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN drug_prescription.id_drug_prescription%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function return all values of report screen create or edit
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient Identifier
     * @param  i_vacc          IN   Vacc ID
     * @param  i_drug          IN   Prescription drug ID
     * 
     * @param  o_form_out      OUT Cursor of all values of report screen   
     * @param  o_doc_show      OUT Y/N Show doc in this screen  
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    07-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_vacc_form_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returned all professional (doctor and nurse) in this institution    
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * 
     * @param  o_prof_list  OUT     Cursor of professional (order by)
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    11-04-2014
     * @author   Jorge Silva
    */
    FUNCTION get_order_by_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return a rout list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_route    rout list
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_route_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_drug    IN mi_med.id_drug%TYPE,
        o_vacc_route OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return default dose 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_dose    return default dose 
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_dose_default
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_drug   IN mi_med.id_drug%TYPE,
        o_vacc_dose OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * List of vaccine funding program eligibility category
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_vacc_type     Return list of vaccine funding program eligibility category
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_funding_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_vacc_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * List of vaccine funding source
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_vacc_source     Return list of vaccine funding source
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_funding_source
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_source OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return all documents filter by vaccine 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    
    * @param OUT  o_vacc_doc    all documents filter by vaccine 
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_doc_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_drug  IN mi_med.id_drug%TYPE,
        o_vacc_doc OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return document filter by barcode
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_barcode_desc    Barcode description
    
    * @param OUT  o_vacc_doc    Return document(description, edition date and id) filter by barcode
    *
    * @author                   Jorge Silva
    * @since                    27/05/2014
    ********************************************************************************************/
    FUNCTION get_vacc_doc_value
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_barcode_desc IN VARCHAR2,
        o_vacc_doc     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This refers to the origin of the vaccine
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_vacc_origin     Return origin of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    13/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_origin_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_origin OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return a description of information source of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_report_id   information source identifier
    *
    * @return     Description of information source
    *
    * @author                   Jorge Silva
    * @since                    22/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_report_description
    (
        i_lang      IN language.id_language%TYPE,
        i_report_id IN vacc_report.id_vacc_report%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This refers to the adverse reaction of the vaccine
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_adv_reaction     Return adverse reaction of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    16/04/2014
    ********************************************************************************************/
    FUNCTION get_adverse_reaction_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_adv_reaction OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to register a administration the new vaccine
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * 
     * @param  o_prof_list  OUT     Cursor of professional (order by)
     *
     * @return   BOOLEAN
     *
     * @version  2.6.4
     * @since    11-04-2014
     * @author   Jorge Silva
    */
    FUNCTION set_pat_administration
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN drug_prescription.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat           IN patient.id_patient%TYPE,
        i_drug_presc    IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_begin      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN drug_presc_det.id_drug%TYPE,
        i_id_vacc       IN vacc.id_vacc%TYPE DEFAULT NULL,
        
        --adverse reaction
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        --Application_spot
        i_application_spot      IN drug_presc_plan.application_spot_code%TYPE DEFAULT '',
        i_application_spot_desc IN drug_presc_plan.application_spot%TYPE,
        
        i_lot_number IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp     IN VARCHAR2,
        
        --Manufactured
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        i_vacc_manuf_desc IN VARCHAR2,
        
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        
        --Administration route
        i_adm_route IN VARCHAR2,
        
        --Vaccine origin
        i_vacc_origin      IN vacc_origin.id_vacc_origin%TYPE,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery IN VARCHAR2,
        i_doc_cat         IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE,
        i_doc_source      IN vacc_funding_source.id_vacc_funding_source%TYPE,
        i_doc_source_desc IN drug_presc_plan.funding_source_desc%TYPE,
        
        --Ordered By
        i_order_by   IN professional.id_professional%TYPE,
        i_order_desc IN VARCHAR2,
        
        --Administer By
        i_administer_by   IN professional.id_professional%TYPE,
        i_administer_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        --Notes
        i_notes IN drug_presc_plan.notes%TYPE,
        
        o_drug_presc_plan OUT NUMBER,
        o_drug_presc_det  OUT NUMBER,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_administration_intern
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN drug_prescription.id_episode%TYPE,
        i_prof       IN profissional,
        i_pat        IN patient.id_patient%TYPE,
        i_drug_presc IN drug_prescription.id_drug_prescription%TYPE,
        i_flg_time   IN drug_prescription.flg_time%TYPE DEFAULT 'E',
        i_dt_begin   IN VARCHAR2,
        
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN drug_presc_det.id_drug%TYPE,
        i_id_vacc       IN vacc.id_vacc%TYPE DEFAULT NULL,
        
        --Old screen
        i_flg_advers_react   IN VARCHAR2,
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        --Application_spot
        i_application_spot      IN drug_presc_plan.application_spot_code%TYPE DEFAULT '',
        i_application_spot_desc IN drug_presc_plan.application_spot%TYPE,
        
        i_lot_number IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp     IN VARCHAR2,
        
        --Manufacturer
        i_vacc_manuf      IN drug_presc_det.id_vacc_manufacturer%TYPE,
        i_vacc_manuf_desc IN drug_presc_det.code_mvx%TYPE,
        
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        
        --Administration route
        i_adm_route IN VARCHAR2,
        
        --Vaccine origin
        i_vacc_origin      IN drug_presc_plan.id_vacc_origin%TYPE,
        i_vacc_origin_desc IN drug_presc_plan.origin_desc%TYPE,
        
        --Docs
        i_doc_vis      IN drug_presc_plan.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery IN VARCHAR2,
        i_doc_cat         IN drug_presc_plan.id_vacc_funding_cat%TYPE,
        i_doc_source      IN drug_presc_plan.id_vacc_funding_source%TYPE,
        i_doc_source_desc IN drug_presc_plan.funding_source_desc%TYPE,
        
        --Ordered By
        i_order_by   IN professional.id_professional%TYPE,
        i_order_desc IN drug_presc_plan.ordered_desc%TYPE,
        
        --Administer By
        i_administer_by   IN professional.id_professional%TYPE,
        i_administer_desc IN drug_presc_plan.administred_desc%TYPE,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        i_test         IN VARCHAR2,
        
        i_notes IN drug_presc_plan.notes%TYPE,
        
        o_drug_presc_plan OUT NUMBER,
        o_drug_presc_det  OUT NUMBER,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return name of vaccine with default value of route and dose
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  Return name of vaccine
    *
    * @author                   Jorge Silva
    * @since                    18/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_description
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN mi_med.id_drug%TYPE,
        i_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a route description
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_drug         Id drug
    * @param IN   i_id_route       toute identifier
    *
    * @return     Route description
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_route_description
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_drug  IN mi_med.id_drug%TYPE,
        i_id_route IN mi_med.route_id%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of manufactured
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_manufactured_id   manufactured identifier
    *
    * @return     Description of manufactured
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_manufacturer_description
    (
        i_lang            IN language.id_language%TYPE,
        i_manufactured_id IN vacc_manufacturer.id_vacc_manufacturer%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of origin
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of origin
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_origin_description
    (
        i_lang      IN language.id_language%TYPE,
        i_origin_id IN vacc_origin.id_vacc_origin%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of origin documents
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of origin documents
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_cat_description
    (
        i_lang        IN language.id_language%TYPE,
        i_vacc_cat_id IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a description of documents source
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_origin_id   origin identifier
    *
    * @return     Description of documents source
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_source_description
    (
        i_lang           IN language.id_language%TYPE,
        i_vacc_source_id IN vacc_funding_source.id_vacc_funding_source%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a adverse reaction description of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_adv_reactions_id   adverse reaction identifier
    *
    * @return     Description of adverse reaction description of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_adv_reactions_description
    (
        i_lang             IN language.id_language%TYPE,
        i_adv_reactions_id IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return a doc description of the vaccine
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_doc_id      doc identifier
    *
    * @return     Description doc description of the vaccine
    *
    * @author                   Jorge Silva
    * @since                    11/04/2014
    ********************************************************************************************/
    FUNCTION get_doc_description
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_doc_id IN vacc_doc_vis.id_vacc_doc_vis%TYPE
    ) RETURN VARCHAR2;

    /************************************************************************************************************
    * Cancel the administration of nvp vacc 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_drug_prescription  id drug prescription 
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Elisabete Bugalho
    * @version    0.1
    * @since      2012-03-13
    ***********************************************************************************************************/
    FUNCTION set_cancel_adm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_drug_prescription IN drug_prescription.id_drug_prescription%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --------------------------------------------------------------------------------

    /************************************************************************************************************
    * Cancel the vaccine prescription
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_vacc_presc_id      vaccine prescrition id
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2008/01/16
    ***********************************************************************************************************/
    FUNCTION set_cancel_other_vacc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --presc_det
        i_vacc_presc_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes_cancel     IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Cancel the administration of nvp vacc 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_drug_prescription  id drug prescription 
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Elisabete Bugalho
    * @version    0.1
    * @since      2012-03-13
    ***********************************************************************************************************/
    FUNCTION set_cancel_report
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_vacc_presc_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Create or edit report administration
    *
    * 
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Elisabete Bugalho
    * @version    0.1
    * @since      2012-03-13
    ***********************************************************************************************************/

    FUNCTION set_pat_report
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_presc         IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_dt_begin_str  IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN mi_med.id_drug%TYPE,
        i_vacc          IN pat_vacc_adm.id_vacc%TYPE,
        
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        i_application_spot_code IN pat_vacc_adm_det.application_spot_code%TYPE,
        i_application_spot      IN pat_vacc_adm_det.application_spot%TYPE DEFAULT '',
        
        i_lot_number        IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str IN VARCHAR2,
        
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        i_vacc_manuf_desc IN VARCHAR2,
        
        i_dosage_admin        IN pat_vacc_adm.dosage_admin%TYPE,
        i_dosage_unit_measure IN pat_vacc_adm.dosage_unit_measure%TYPE,
        
        i_adm_route IN VARCHAR2,
        
        i_vacc_origin      IN pat_vacc_adm_det.id_vacc_origin%TYPE DEFAULT NULL,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery     IN VARCHAR2,
        i_vacc_funding_cat    IN pat_vacc_adm_det.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source IN pat_vacc_adm_det.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc IN pat_vacc_adm_det.funding_source_desc%TYPE DEFAULT NULL,
        
        i_information_source IN pat_vacc_adm_det.id_information_source%TYPE,
        i_report_orig        IN pat_vacc_adm_det.report_orig%TYPE,
        
        i_administred      IN pat_vacc_adm_det.id_administred%TYPE DEFAULT NULL,
        i_administred_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        i_notes IN pat_vacc_adm_det.notes%TYPE,
        
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return name of vaccine with date of dose adminstration 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_vacc         Vaccine id
    * @param IN   i_drug            Drug prescription ID
    *
    * @param OUT  o_desc            Return name of vaccine with date of dose adminstration 
    *
    * @author                   Jorge Silva
    * @since                    22/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_adm_take_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_drug    IN drug_prescription.id_drug_prescription%TYPE,
        o_desc    OUT VARCHAR2
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return name of vaccine with date of dose report 
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_id_vacc         Vaccine id
    * @param IN   i_pat_vacc_adm    Report prescription ID
    *
    * @param OUT  o_desc            Return name of vaccine with date of dose report 
    *
    * @author                   Jorge Silva
    * @since                    22/04/2014
    ********************************************************************************************/
    FUNCTION get_vacc_rep_take_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_vacc      IN vacc.id_vacc%TYPE,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_desc         OUT VARCHAR2
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the details for all takes for the specified vaccine.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_vacc_id            vaccine's id
    *
    * @param      o_adm                detail of administration (Date of administration)
    * @param      o_desc               cursor with the description details
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/
    FUNCTION get_vacc_details
    
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        o_adm     OUT pk_types.cursor_type,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function checks whether the taking was made in the same episode
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_take_id            take id
    * @param      i_flg                Flag identifying the type of report 
    *
    *
    * @return     This function checks whether the taking was made in the same episode (A/I)
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/

    FUNCTION has_recorded_this_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_take_id IN NUMBER,
        i_flg     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_description_adm_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN drug_prescription.id_drug_prescription%TYPE,
        i_vacc IN vacc.id_vacc%TYPE
    ) RETURN CLOB;

    FUNCTION get_description_report_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_vacc         IN vacc.id_vacc%TYPE
    ) RETURN CLOB;

    FUNCTION get_has_adm_canceled(i_drug IN drug_prescription.id_drug_prescription%TYPE) RETURN VARCHAR2;

    FUNCTION get_has_rep_canceled(i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE) RETURN VARCHAR2;

    FUNCTION get_desc_adm_cancel_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_drug IN drug_prescription.id_drug_prescription%TYPE
    ) RETURN CLOB;

    FUNCTION get_desc_rep_cancel_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE
    ) RETURN CLOB;

    FUNCTION set_vacc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_status     IN pat_vacc.flg_status%TYPE,
        i_id_reason  IN NUMBER,
        i_notes      IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient vaccine status.
    *
    * @param i_patient      logged professional structure
    * @param i_vacc         presc type flag
    *
    * @return               patient vaccine status
    *
    * @author               Elisabete Bugalho
    * @version               2.5.3
    * @since                2012/05/31
    */
    FUNCTION get_vacc_status
    (
        i_patient IN patient.id_patient%TYPE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN pat_vacc.flg_status%TYPE;

    FUNCTION has_active_option
    (
        i_status IN VARCHAR2,
        i_option IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION has_discontinue_dose
    (
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;

    FUNCTION has_discontinue_vacc
    (
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
      * Return name of vaccine with last take 
        *
        * @param IN   i_lang            Language ID
        * @param IN   i_prof            Professional ID
        * @param IN   i_id_vacc         Vaccine id
        * @param IN   i_dose            Dose (-1 dose selected or null)
        *
        * @param OUT  Return name of vaccine with date of dose report 
        *
        * @author                   Jorge Silva
        * @since                    05/05/2014
    ********************************************************************************************/
    FUNCTION get_vacc_descontinue_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_dose    IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_desc_disc_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_vacc_hist IN pat_vacc_hist.id_pat_vacc_hist%TYPE
    ) RETURN CLOB;

    FUNCTION set_discontinue_dose
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_vacc            IN pat_vacc_adm.id_vacc%TYPE,
        i_id_reason_sus   IN pat_vacc_adm_det.id_reason_sus%TYPE,
        i_suspended_notes IN pat_vacc_adm_det.suspended_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_resume_dose
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_vacc       IN pat_vacc_adm.id_vacc%TYPE,
        i_drug       IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_desc_disc_dose_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE
    ) RETURN CLOB;

    /************************************************************************************************************
    * This function 
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_take_id            take id
    * @param      i_flg                Flag identifying the type of report 
    *
    *
    * @return     This function checks whether the taking was made in the same episode (A/I)
    * @author     Jorge Silva
    * @version    0.1
    * @since      2014/04/24
    ***********************************************************************************************************/

    FUNCTION get_description_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        i_labels  IN table_varchar2,
        i_res     IN table_varchar2,
        i_dt      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_updated IN VARCHAR2
    ) RETURN CLOB;

    /**
     * This function returned if a next date is enabled or not
     *
     * @param  i_lang          IN   Language ID
     * @param  i_prof          IN   Professional structure
     * @param  i_patient       IN   Patient ID
     * @param  i_tk_date       IN   Take Date
     * @param  i_vacc          IN   Vacc ID
     * @param  i_dt_adm_str    IN   Date Administration
     * 
     * @return  next date is available (Y/N)
     *
     * @version  2.6.4.0.2
     * @since    22-05-2014
     * @author   Jorge Silva
    */
    FUNCTION get_next_date_available
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_tk_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vacc    IN vacc.id_vacc%TYPE
    ) RETURN VARCHAR2;
    g_package_name VARCHAR2(32);

    g_package_owner CONSTANT obj_name := 'ALERT';
    g_package_names CONSTANT obj_name := pk_alertlog.who_am_i();

    l_green_color          CONSTANT VARCHAR2(50) := '0x829664';
    l_red_color            CONSTANT VARCHAR2(50) := '0xC86464';
    l_normal_color         CONSTANT VARCHAR2(50) := '0xEBEBC8';
    g_vacc_icon_check_take CONSTANT VARCHAR2(15) := 'CheckIcon';

    g_vacc_icon_report_take CONSTANT VARCHAR2(50) := 'PrescriptionReportedByIcon';

    --Icons
    g_cancel_icon           CONSTANT VARCHAR2(50) := 'CancelIcon';
    g_waitingicon           CONSTANT VARCHAR2(50) := 'WaitingIcon';
    g_presc_prescribed_icon CONSTANT VARCHAR2(50) := 'PrescriptionPrescribedIcon';
    g_not_icon              CONSTANT VARCHAR2(50) := 'NotNeededIcon';

    g_orig_r CONSTANT VARCHAR2(1) := 'R';
    g_orig_v CONSTANT VARCHAR2(1) := 'V';
    g_orig_i CONSTANT VARCHAR2(1) := 'I'; -- origem do registo na PAT_VACC_ADM: importação SINUS

    g_med_e CONSTANT VARCHAR2(1) := 'E';
    g_med_i CONSTANT VARCHAR2(1) := 'I';

    g_vacc_presc_canc CONSTANT VARCHAR2(1) := 'C';

    g_vacc_presc_det_canc CONSTANT VARCHAR2(1) := 'C';
    g_vacc_presc_det_fin  CONSTANT VARCHAR2(1) := 'A';
    g_vacc_presc_det_req  CONSTANT VARCHAR2(1) := 'R';
    g_vacc_presc_det_d    CONSTANT VARCHAR2(1) := 'D';

    g_vacc_status_edit CONSTANT VARCHAR2(1) := 'E';

    g_flg_time_next CONSTANT VARCHAR2(1) := 'N';

    g_vacc_presc_par CONSTANT VARCHAR2(1) := 'P';
    g_vacc_presc_res CONSTANT VARCHAR2(1) := 'A';
    g_flg_time_e     CONSTANT pat_vacc_adm.flg_time%TYPE := 'E';

    g_flg_status_p CONSTANT prescription.flg_status%TYPE := 'P';

    g_drug_presc_det_f CONSTANT drug_presc_det.flg_status%TYPE := 'F';

    --Prescription table name, for prescription_instr_hist
    g_drug_presc_det CONSTANT VARCHAR2(20) := 'DRUG_PRESC_DET';

    -- constantes associadas aos tipos de prescrições possíveis na àrea de vacinas
    g_flg_presc_pnv        vacc_type_group.flg_presc_type%TYPE := 'P';
    g_flg_presc_tuberculin vacc_type_group.flg_presc_type%TYPE := 'T';
    g_flg_presc_other_vacc vacc_type_group.flg_presc_type%TYPE := 'O';

    -- Constants used for reports purpose (by episode; by visit; by patient)
    g_rep_type_patient CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_rep_type_visit   CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_rep_type_episode CONSTANT VARCHAR2(1 CHAR) := 'E';

    g_domain_application_spot     sys_domain.code_domain%TYPE := 'DRUG_PRESC_PLAN.APPLICATION_SPOT';
    g_domain_notes_adv_react_list sys_domain.code_domain%TYPE := 'DRUG_PRESC_PLAN.NOTES_ADVERS_REACT';
    g_presc_take_cont CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_presc_fin    drug_prescription.flg_status%TYPE := 'F';
    g_flg_new_vacc drug.flg_type%TYPE := 'V';

    g_presc_plan_stat_adm drug_presc_det.flg_status%TYPE := 'A';

    g_presc_det_fin drug_presc_det.flg_status%TYPE := 'F';
    g_flg_time_betw CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_drug_interv   CONSTANT VARCHAR2(1 CHAR) := 'M';

    g_presc_take_uni drug_presc_det.flg_take_type%TYPE := 'U';

    g_presc_det_exe CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_presc_par     CONSTANT VARCHAR2(1 CHAR) := 'P';

    g_presc_type_int drug_prescription.flg_type%TYPE := 'I';

    g_presc_req drug_prescription.flg_status%TYPE := 'R';

    g_presc_plan_stat_req  drug_presc_plan.flg_status%TYPE := 'R';
    g_presc_plan_stat_pend drug_presc_plan.flg_status%TYPE := 'D';

    g_cat_type_nurse CONSTANT VARCHAR2(1 CHAR) := 'N';

    g_vacc_dose_report CONSTANT VARCHAR2(1 CHAR) := 'R'; -- Relato de dose administrada
    g_vacc_dose_int    CONSTANT VARCHAR2(1 CHAR) := 'I'; -- Relato vindo do SINUS
    g_vacc_dose_adm    CONSTANT VARCHAR2(1 CHAR) := 'V'; -- Administração

    g_vacc_tetano pat_vacc_adm.id_pat_vacc_adm%TYPE := 15;

    g_other_label          CONSTANT VARCHAR2(100 CHAR) := 'COMMON_M041';
    g_administration_label CONSTANT VARCHAR2(100 CHAR) := 'MED_PRESC_T201';

    g_other_value CONSTANT NUMBER := -1;

    g_vaccine_title        CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_administration_title CONSTANT VARCHAR2(1 CHAR) := 'A';

    --Details labels
    g_name_vacc_details          CONSTANT VARCHAR2(15 CHAR) := 'VACC_T005'; --Type / vaccine / dose
    g_adm_details                CONSTANT VARCHAR2(15 CHAR) := 'VACC_T112'; --Administration date/time
    g_adm_dose_details           CONSTANT VARCHAR2(15 CHAR) := 'VACC_T113'; --Administered dose amount
    g_adm_route_details          CONSTANT VARCHAR2(15 CHAR) := 'VACC_T123'; --Administration route
    g_adm_site_details           CONSTANT VARCHAR2(15 CHAR) := 'VACC_T124'; --Administration site
    g_manufactured_details       CONSTANT VARCHAR2(15 CHAR) := 'VACC_T085'; --Manufacturer name
    g_lot_details                CONSTANT VARCHAR2(15 CHAR) := 'VACC_T007'; --Lot
    g_exp_date_details           CONSTANT VARCHAR2(15 CHAR) := 'VACC_T008'; --Expiration date
    g_origin_details             CONSTANT VARCHAR2(15 CHAR) := 'VACC_T111'; --Vaccine origin
    g_doc_vis_details            CONSTANT VARCHAR2(15 CHAR) := 'VACC_T118'; --VIS document type (edition date)
    g_doc_vis_date_details       CONSTANT VARCHAR2(15 CHAR) := 'VACC_T119'; --VIS presentation date
    g_doc_cat_details            CONSTANT VARCHAR2(15 CHAR) := 'VACC_T116'; --Vaccine funding program eligibility category
    g_doc_source_details         CONSTANT VARCHAR2(15 CHAR) := 'VACC_T117'; --Vaccine funding source
    g_ordered_details            CONSTANT VARCHAR2(15 CHAR) := 'VACC_T114'; --Ordered by
    g_adm_by_details             CONSTANT VARCHAR2(15 CHAR) := 'VACC_T115'; --Administered by
    g_next_dose_details          CONSTANT VARCHAR2(15 CHAR) := 'VACC_T125'; --Next dose schedule
    g_adv_reaction_details       CONSTANT VARCHAR2(15 CHAR) := 'VACC_T009'; --Adverse reactions
    g_notes_details              CONSTANT VARCHAR2(15 CHAR) := 'VACC_T020'; --Notes                                                        
    g_information_source_details CONSTANT VARCHAR2(15 CHAR) := 'VACC_T120'; --Information source                                                        
    g_adm_title_details          CONSTANT VARCHAR2(15 CHAR) := 'VACC_T129'; --Administration     
    g_adm_edit_title_details     CONSTANT VARCHAR2(15 CHAR) := 'VACC_T130'; --Administration edition
    g_rep_title_details          CONSTANT VARCHAR2(15 CHAR) := 'VACC_T131'; --Report     
    g_rep_edit_title_details     CONSTANT VARCHAR2(15 CHAR) := 'VACC_T132'; --Report edition
    g_cancel_reason_details      CONSTANT VARCHAR2(15 CHAR) := 'COMMON_M072'; --Cancellation reason
    g_cancel_notes_details       CONSTANT VARCHAR2(15 CHAR) := 'COMMON_M073'; --Cancellation notes
    g_cancel_title_details       CONSTANT VARCHAR2(15 CHAR) := 'COMMON_T032'; --Cancellation
    g_documented_details         CONSTANT VARCHAR2(25 CHAR) := 'DOCUMENTATION_MACRO_M024'; --Documented:
    g_updated_details            CONSTANT VARCHAR2(25 CHAR) := 'DOCUMENTATION_MACRO_M023'; --Updated:

    g_vacc_title_discontinue CONSTANT VARCHAR2(25 CHAR) := 'VACC_T134'; --Discontinuation
    g_vacc_title_resume      CONSTANT VARCHAR2(25 CHAR) := 'VACC_T133'; --Resume

    g_vacc_title_adv_react CONSTANT VARCHAR2(25 CHAR) := 'VACC_T084'; --Record adverse reaction

    g_vacc_sub_title_discontinue CONSTANT VARCHAR2(25 CHAR) := 'VACC_T137'; --Scheduled
    g_vacc_dose_sch_details      CONSTANT VARCHAR2(25 CHAR) := 'VACC_T135'; --Dose schedule
    g_vacc_adm                   CONSTANT VARCHAR2(25 CHAR) := 'VACC_T129'; --Administration
    g_vacc_discontinue           CONSTANT VARCHAR2(25 CHAR) := 'VACC_T138'; --Vaccine

    g_vacc_no_app CONSTANT VARCHAR2(25 CHAR) := 'COMMON_M018'; --'No applicable'

    g_reason CONSTANT VARCHAR2(25 CHAR) := 'VACC_T140'; --Reason

    g_status_s CONSTANT pat_vacc.flg_status%TYPE := 'S'; --Discontinue
    g_status_a CONSTANT pat_vacc.flg_status%TYPE := 'A'; --Resume vaccinse
    g_status_r CONSTANT pat_vacc.flg_status%TYPE := 'R'; --Resume dose

    g_year  CONSTANT VARCHAR2(1 CHAR) := 'Y'; --Year
    g_month CONSTANT VARCHAR2(1 CHAR) := 'M'; --Month
    g_day   CONSTANT VARCHAR2(1 CHAR) := 'D'; --Day
END pk_vacc;
/
