/*-- Last Change Revision: $Rev: 2020420 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-07-29 16:02:18 +0100 (sex, 29 jul 2022) $*/

CREATE OR REPLACE PACKAGE pk_episode_ux IS

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
    --

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

    /******************************************************************************
       OBJECTIVO:   Retornar info do doente q ?mostrada na cabeçalho da aplicação
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                  I_ID_PAT - ID do doente
                 I_ID_EPISODE - Tipo de episódio
            Saida:   O_DESC_INFO - info do doente
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/03/16
      NOTAS:
    *********************************************************************************/
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

    /******************************************************************************
       OBJECTIVO:   Retornar se se trata de uma 1?consulta ou subsequente da
               especialidade indicada
       PARAMETROS:  Entrada: I_LANG - Língua
                  I_ID_PAT - ID do utente
                 I_ID_CLIN_SERV - ID do tipo de serviço clínico
                 I_INSTITUTION - ID da instituição
                 I_EPIS_TYPE - ID do tipo de episódio
            Saida:   O_FLG - P - 1?consulta
                       S - subsequente
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/01/25
      NOTAS:
    *********************************************************************************/
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

    /******************************************************************************
       OBJECTIVO:   Retornar n?do epis do Sonho, data de efectivação (= data início) e
               data de atendimento
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
            Saida:   O_DT_EFECTIV - Tipo de episódio
                 O_DESC_INFO - info do doente
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/03/17
      ALTERAÇÃO: ASM 2007/04/06
    
      NOTAS:
    *********************************************************************************/
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

    /******************************************************************************
       OBJECTIVO:   Retornar episódios fechados de um doente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_PAT - ID do doente
                 I_TYPE - tipo de episódio. Se ?estiver preenchido, retorna
                       os epis. de qq tipo. Para a cons. externa ?1
            Saida:   O_EPIS - episódios
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/04/01
      NOTAS:
    *********************************************************************************/
    FUNCTION get_prev_episode
    (
        i_lang  IN language.id_language%TYPE,
        i_pat   IN patient.id_patient%TYPE,
        i_type  IN episode.id_epis_type%TYPE,
        i_prof  IN profissional,
        o_epis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --
    /********************************************************************************************
    * Página resumo
    *
    * @param i_lang              language id
    * @param i_pat               patient id
    * @param i_epis               episode id
    * @param i_prof              professional, software and institution ids
    * @param o_complaint      complaint
    * @param o_history      array with info history
    * @param o_fam_hist      array with info family history
    * @param o_soc_hist      array with info social history
    * @param o_allergy      array with info allergy
    * @param o_habit      array with info habits
    * @param o_relev_disease      array with info relev disease
    * @param o_relev_notes      array with info relevantes notes
    * @param o_medication      array with info medications
    * @param o_info10           array with info
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Susana Seixas
    * @since                     2006/02/27
    
    * @alter                    Emília Taborda
    * @since                     2006/06/21
    ********************************************************************************************/
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
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Página resumo
    *
    * @param i_lang              language id
    * @param i_pat               patient id
    * @param i_epis               episode id
    * @param i_prof              professional, software and institution ids
    * @param i_review            indicates if the summary includes Review of system
    * @param o_complaint      complaint
    * @param o_history      array with info history
    * @param o_review      array with info of review of system
    * @param o_fam_hist      array with info family history
    * @param o_soc_hist      array with info social history
    * @param o_allergy      array with info allergy
    * @param o_habit      array with info habits
    * @param o_relev_disease      array with info relev disease
    * @param o_relev_notes      array with info relevantes notes
    * @param o_medication      array with info medications
    * @param o_info10           array with info
    
    * @param o_error             Error message
    
    * @return                    true or false on success or error
    *
    * @author                    Susana Seixas
    * @since                     2006/02/27
    
    * @alter                    Emília Taborda
    * @since                     2006/06/21
    * @alter                    Orlando Antunes
    * @since                     2007/10/01
    * NOTAS: Esta função deve ser completamente remodelada!
    * @alter                    Rita Lopes
    * @since                     2008/03/20
    * Alterar a flg da medicação anterior de C para D
    ********************************************************************************************/
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
    --
    --

    /******************************************************************************
       OBJECTIVO:
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
             I_PAT - ID do paciente
                 I_EPIS - ID do episódio
                 I_PROF - profissional que acede
            Saída: O_INFO - informação
                 O_ERROR - erro
    
      CRIAÇÃO: SS 2006/02/27
      ALTERADO: ET 2006/06/21
      NOTAS: RdSN 2007/02/18 Recebe um array de episódios em vez de um NUMBER (necessário p/ Saúde Materna)
      ALTERADO: Orlando Antunes 2006/10/03
      NOTAS: Esta função deve ser completamente remodelada!
    *********************************************************************************/
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

    /******************************************************************************
       OBJECTIVO:
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
             I_PAT - ID do paciente
                 I_EPIS - ID do episódio
                 I_PROF - profissional que acede
            Saída: O_INFO - informação
                 O_ERROR - erro
    
      CRIAÇÃO: SS 2006/02/27
      NOTAS: RdSN 2007/02/18 Recebe um array de episódios em vez de um NUMBER (necessário p/ Saúde Materna)
    *********************************************************************************/
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

    /******************************************************************************
       OBJECTIVO:
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
             I_PAT - ID do paciente
                 I_EPIS - ID do episódio
                 I_PROF - profissional que acede
            Saída: O_INFO - informação
                 O_ERROR - erro
    
      CRIAÇÃO: SS 2006/02/27
      NOTAS: RdSN 2007/02/18 Recebe um array de episódios em vez de um NUMBER (necessário p/ Saúde Materna)
      CHANGE: Elisabete Bugalho
          ALERT-19202 : Separar os procedimento MFR dos restantes procedimentos
    *********************************************************************************/
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

    /******************************************************************************
       OBJECTIVO:    Registar o espólio do paciente neste episódio
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_ID_EPIS - ID do Episódio do profissional
                 I_DESC_ESTATE- Descrição do espólio
                 I_PROF - ID do profissional q regista
    
            Saida: O_ERROR - erro
    
      CRIAÇÃO: SF 2006/06/16
      NOTAS:
    *********************************************************************************/
    FUNCTION create_estate_epis
    (
        i_lang        IN language.id_language%TYPE,
        i_id_epis     IN estate.id_episode%TYPE,
        i_desc_estate IN estate.desc_estate%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_type_new
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_epis   IN episode.id_episode%TYPE,
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
    
    * @notes                     This function should not be used by the flash layer
    ********************************************************************************************/
    FUNCTION get_epis_type
    (
        i_lang      IN language.id_language%TYPE,
        i_id_epis   IN social_episode.id_social_episode%TYPE,
        o_epis_type OUT episode.id_epis_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Listar o espólio do paciente num episódio
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_PROF - ID do profissional
                 I_ID_EPIS - ID  do Episódio
    
            Saida:   O_S_EPIS - Retorna o espólio do paciente do episódio
                 O_ERROR - erro
    
      CRIAÇÃO: SF 2006/06/16
      ALTERAÇÃO: ET 2007/04/10 Filtrar os exames também com ID_PREV_EPISODE=I_ID_EPIS
      NOTAS:
    *********************************************************************************/
    FUNCTION get_estate_epis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis     IN social_episode.id_social_episode%TYPE,
        o_estate_epis OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Retornar o descritivo a dizer se o paciente tem ou não alergias a fármacos conhecidas
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_PROF - ID do profissional
                 I_ID_PAT - ID do paciente
           Saida:   O_NKDA - descritivo
                 O_ERROR - erro
      CRIAÇÃO: ASM 2007/01/30
      NOTAS:
    *********************************************************************************/
    FUNCTION get_nkda_label
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_pat IN patient.id_patient%TYPE,
        o_nkda   OUT VARCHAR2,
        o_error  OUT t_error_out
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

    --
    /**********************************************************************************************
    * Actualizar o episódio de origem do espólio bem como as respectivas tabelas de relação.
      Utilizada aquando a passagem de Urgência para Internamento ser?necessário actualizar o ID_EPISODE no espólio
      com o novo episódio (INP) e o ID_EPISODE_ORIGIN ficar?com o episódio de urgência (EDIS)
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

    /**
    * Returns an episode clinical service.
    * a identificação do clinical_service, no internamento, não se encontra na tabela episode, mas sim na tabela dep_clin_serv.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                episode identifier
    *
    * @return               notes
    *
    * @author               Sofia Mendes
    * @version               2.5
    * @since                20/03/2013
    */
    FUNCTION get_epis_clin_serv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_clin_serv OUT clinical_service.id_clinical_service%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prev_epis_summary
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_type              IN VARCHAR2,
        i_search                IN NUMBER,
        i_epis_type             IN epis_type.id_epis_type%TYPE,
        i_id_epis_hhc_req       IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_info                  OUT pk_types.cursor_type,
        o_doc_area_register     OUT  pk_types.cursor_type,--pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val          OUT  pk_types.cursor_type,--pk_touch_option.t_cur_doc_area_val,
        o_template_layouts      OUT  pk_types.cursor_type,
        o_doc_area_component    OUT  pk_types.cursor_type,
        o_brief_desc            OUT pk_types.cursor_type,
        o_desc_doc_area         OUT pk_types.cursor_type,
        o_desc_doc_area_detail  OUT pk_types.cursor_type,
        o_supp_list             OUT pk_types.cursor_type,
        o_nurse_teach           OUT pk_types.cursor_type,
        o_diag                  OUT pk_types.cursor_type,
      --  o_impressions           OUT pk_types.cursor_type,
        o_warning_msg           OUT pk_translation.t_desc_translation,
     --   o_ass_scales            OUT pk_types.cursor_type,
     --   o_doc_area_register_obs OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obtenção dos dados dos episódios anteriores
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
              I_PATIENT - ID do paciente
              I_PROF - ID do profissional
              ...
            Saida: O_ERROR - Erro
    
      CRIAÇÃO: ASM 2007/05/23
      NOTAS: Dados de retorno semelhantes aos do GET_SUMMARY_S, GET_SUMMARY_O, etc
    *********************************************************************************/
    FUNCTION get_prev_epis_det
    (
        i_lang                   IN language.id_language%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN table_number,
        i_prof                   IN profissional,
        o_complaint              OUT pk_types.cursor_type,
        o_allergy                OUT pk_types.cursor_type,
        o_habit                  OUT pk_types.cursor_type,
        o_relev_disease          OUT pk_types.cursor_type,
        o_relev_notes            OUT pk_types.cursor_type,
        o_medication             OUT pk_types.cursor_type,
        o_home_med_review        OUT pk_types.cursor_type,
        o_pat_take               OUT pk_types.cursor_type,
        o_vital_sign             OUT pk_types.cursor_type,
        o_biometric              OUT pk_types.cursor_type,
        o_blood_group            OUT pk_types.cursor_type,
        o_info7                  OUT pk_types.cursor_type,
        o_problems               OUT pk_types.cursor_type,
        o_ass_scales             OUT pk_types.cursor_type,
        o_body_diags             OUT pk_types.cursor_type,
        o_diag                   OUT pk_types.cursor_type,
        o_impressions            OUT pk_types.cursor_type,
        o_evaluation             OUT pk_types.cursor_type,
        o_analysis               OUT pk_types.cursor_type,
        o_exam                   OUT pk_types.cursor_type,
        o_presc_ext              OUT pk_types.cursor_type,
        o_dietary_ext            OUT pk_types.cursor_type,
        o_manip_ext              OUT pk_types.cursor_type,
        o_presc                  OUT pk_types.cursor_type,
        o_interv                 OUT pk_types.cursor_type,
        o_monitorization         OUT pk_types.cursor_type,
        o_nurse_act              OUT pk_types.cursor_type,
        o_nurse_teach            OUT pk_types.cursor_type,
        o_referrals              OUT pk_types.cursor_type,
        o_gp_notes               OUT pk_types.cursor_type,
        o_doc_area_register      OUT pk_types.cursor_type,--pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val           OUT pk_types.cursor_type,--pk_touch_option.t_cur_doc_area_val,
        o_template_layouts       OUT pk_types.cursor_type,
        o_doc_area_component     OUT pk_types.cursor_type,
        o_cits                   OUT pk_types.cursor_type,
        o_discharge_instructions OUT pk_types.cursor_type,
        o_discharge              OUT pk_types.cursor_type,
        o_surgical_hist          OUT pk_types.cursor_type,
        o_past_hist_ft           OUT pk_types.cursor_type,
        o_surgery_record         OUT pk_types.cursor_type,
        o_risk_factors           OUT pk_types.cursor_type,
          o_obstetric_history OUT pk_types.cursor_type,
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
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jos?Brito
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
    --
    --
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
    * @author                  Jos?Brito
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

    /**********************************************************************************************
    *  This fuction will update the table viewer_ehr_ea for the specified patients.
    *
    * @param I_LANG                   The id language
    * @param I_TABLE_ID_PATIENTS      Table of id patients to be clean.
    * @param O_ERROR                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         ANA COELHO
    * @version                        1.0
    * @since                          27-APR-2011
    **********************************************************************************************/
    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @param i_prof                   Professional
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
    * @author  Jos?Silva
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

    /*******************************************************************************************
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
    ) RETURN BOOLEAN;

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

    FUNCTION get_episode_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

END pk_episode_ux;
/
