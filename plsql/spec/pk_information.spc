/*-- Last Change Revision: $Rev: 2028739 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_information IS

    -- Author  : SUSANA
    -- Created : 27-04-2007 9:43:49
    -- Purpose : Functions for Information Desk profile

    /** 
    * Public Function. Retornar os dados para o cabeçalho da aplicação 
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_ID_PAT            ID do doente 
    * @param      I_ID_EPISODE        ID do episódio
    * @param      O_NAME              nome completo 
    * @param      O_GENDER            sexo do doente 
    * @param      O_AGE               idade do doente 
    * @param      O_HEALTH_PLAN       subsistema de saúde do utente
    * @param      O_COMPL_PAIN        Queixa completa 
    * @param      O_INFO_ADIC         Informação adicional (descrição da categoria + data da última alteração +nome do profissional)
    * @param      O_CAT_PROF          Categoria do profissional  
    * @param      O_CAT_NURSE         Categoria da enfermeira
    * @param      O_COMPL_DIAG        Diagnósticos
    * @param      O_PROF_NAME         nome do médico da consulta 
    * @param      O_NURSE_NAME        Nome da enfermeira
    * @param      O_PROF_SPEC         especialidade do médico da urgência
    * @param      O_NURSE_SPEC        especialidade da enfermeira da urgência
    * @param      O_ACUITY            Acuidade
    * @param      O_EPISODE           nº episódio no sistema externo e título
    * @param      O_CLIN_REC          nº do processo clínico na instituição onde se está a aceder à aplicação (SYS_CONFIG) e título
    * @param      O_LOCATION          localização e título 
    * @param      O_TIME_ROOM         tempo na sala 
    * @param      O_ADMIT             tempo de admissão e título
    * @param      O_TOTAL_TIME        tempo total
    * @param      O_PAT_PHOTO         URL da directoria da foto do doente
    * @param      O_PROF_PHOTO        URL da directoria da foto do profissional
    * @param      O_HABIT             nº de hábitos
    * @param      O_ALLERGY           nº de alergias 
    * @param      O_PREV_EPIS         nº de episódios anteriores 
    * @param      O_RELEV_DISEASE     nº de doenças relevantes 
    * @param      O_BLOOD_TYPE        tipo sanguíneo 
    * @param      O_RELEV_NOTE        notas relevantes 
    * @param      O_APPLICATION       área aplicacional
    * @param      O_INFO              Língua registada como preferência do profissional
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2007/01/04
    */

    FUNCTION get_clinical_service(i_lang IN language.id_language%TYPE,
                                  
                                  i_prof    IN profissional,
                                  i_episode IN episode.id_episode%TYPE) RETURN VARCHAR2;

    /**
    * Public Function. Obter a descrição da categoria do profissional  
    * Não é utilizada pelo flash. 
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_PROF              ID do profissional 
    * @param      O_CAT_PROF          descrição da categoria
    * @param      O_FLG_TYPE              Tipo de categoria
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     SS
    * @version    0.1
    * @since      2007/01/04
    */
    FUNCTION get_category_prof
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_prof  IN professional.id_professional%TYPE,
        o_cat      OUT VARCHAR2,
        o_flg_type OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Information desk grid for active episodes: shows no registered episodes and registered episodes without administrative discharge
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_active            Active episodes 
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     CRS
     * @version    0.1
     * @since      2005/04/07 
    **********************************************************************************************/
    FUNCTION information_active
    (
        i_lang      IN language.id_language%TYPE,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_active    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Detailed information of the selected episode
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_epis              Episode ID 
     * @param      i_pat               Patient ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_active            Detailed info 
     * @param      o_titles            Titles to show
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2005/12/26 
    **********************************************************************************************/
    FUNCTION information_active_det
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        i_pat    IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_active OUT pk_types.cursor_type,
        o_titles OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Information desk grid for inactive episodes: shows episodes with administrative discharge
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_dt                Schedule date. If is NULL, consider the actual date 
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_inactive          Inactive episodes 
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     CRS
     * @version    0.1
     * @since      2005/04/07 
    **********************************************************************************************/
    FUNCTION information_inactive
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_inactive  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Inactive episodes of the selected patient
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_pat               Patient ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_inactive          Inactive episodes
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2005/12/26 
    **********************************************************************************************/
    FUNCTION information_inactive_det
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_inactive OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_search_list
    (
        i_lang               IN language.id_language%TYPE,
        i_id_sys_button      IN search_screen.id_sys_button%TYPE,
        i_prof               IN profissional,
        o_list               OUT pk_types.cursor_type,
        o_list_cs            OUT pk_types.cursor_type,
        o_list_fs            OUT pk_types.cursor_type,
        o_list_payment_state OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Search active patients that meet the selected criteria   
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_id_sys_btn_crit   Search criteria IDs  
     * @param      i_crit_val          Search criteria values    
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_dt                Search date. If is NULL, consider SYSDATE
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_flg_show          flag that indicates whether there's a message to show or not  
     * @param      o_msg               message to show
     * @param      o_msg_title         message title
     * @param      o_button            button to show 
     * @param      o_pat               active patients 
     * @param      o_mess_no_result    message to show if there are no results 
     * @param      o_error             error
     *
    
     * @value      o_flg_show          {*} 'Y' there's a message to show to the user
                                       {*} 'N' no message to show
     * @value      o_button            {*} 'R' read
                                       {*} 'N' no
                                       {*} 'C' confirmed
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2007/04/27
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN DATE,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Search inactive patients that meet the selected criteria   
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_id_sys_btn_crit   Search criteria IDs  
     * @param      i_crit_val          Search criteria values    
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_dt                Search date. If is NULL, consider SYSDATE
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      i_prof_cat_type     Professional's category type
     * @param      o_flg_show          Flag that indicates whether there's a message to show or not  
     * @param      o_msg               Message to show
     * @param      o_msg_title         Message title
     * @param      o_button            Button to show 
     * @param      o_pat               Inactive patients 
     * @param      o_mess_no_result    Message to show if there are no results 
     * @param      o_error             Error
     *
    
     * @value      o_flg_show          {*} 'Y' there's a message to show to the user
                                       {*} 'N' no message to show
     * @value      o_button            {*} 'R' read
                                       {*} 'N' no
                                       {*} 'C' confirmed
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2007/04/27
    **********************************************************************************************/
    FUNCTION get_pat_criteria_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN DATE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Search scheduled patients that meet the selected criteria   
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_id_sys_btn_crit   Search criteria IDs  
     * @param      i_crit_val          Search criteria values    
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      i_prof_cat_type     Professional's category type
     * @param      o_flg_show          Flag that indicates whether there's a message to show or not  
     * @param      o_msg               Message to show
     * @param      o_msg_title         Message title
     * @param      o_button            Button to show 
     * @param      o_pat               Scheduled patients 
     * @param      o_mess_no_result    Message to show if there are no results 
     * @param      o_error             Error
     *
    
     * @value      o_flg_show          {*} 'Y' there's a message to show to the user
                                       {*} 'N' no message to show
     * @value      o_button            {*} 'R' read
                                       {*} 'N' no
                                       {*} 'C' confirmed
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2007/04/27
    **********************************************************************************************/
    FUNCTION get_pat_crit_sched
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_found        BOOLEAN;
    g_sysdate      DATE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(2000);

    ---------
    g_patient_active     VARCHAR2(1) := 'A';
    g_pat_blood_active   VARCHAR2(1) := 'A';
    g_default_hplan_y    VARCHAR2(1) := 'Y';
    g_hplan_active       VARCHAR2(1) := 'A';
    g_epis_cancel        VARCHAR2(1) := 'C';
    g_no_triage          VARCHAR2(1) := 'N';
    g_epis_diag_act      VARCHAR2(1) := 'A';
    g_pat_allergy_cancel VARCHAR2(1) := 'C';
    g_pat_habit_cancel   VARCHAR2(1) := 'C';
    g_pat_problem_cancel VARCHAR2(1) := 'C';
    g_pat_notes_cancel   VARCHAR2(1) := 'C';

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

    g_flg_without VARCHAR2(2) := 'YF';

    --grelhas
    g_epis_active   episode.flg_status%TYPE := 'A';
    g_epis_inactive episode.flg_status%TYPE := 'I';
    g_epis_canc     episode.flg_status%TYPE := 'C';

    g_sched_canc      schedule.flg_status%TYPE := 'C';
    g_sched_adm_disch schedule_outp.flg_state%TYPE := 'M';

    g_flg_status_f drug_prescription.flg_status%TYPE := 'F';
    g_flg_status_p drug_prescription.flg_status%TYPE := 'P';
    g_flg_status_r drug_prescription.flg_status%TYPE := 'R';
    g_flg_status_a drug_prescription.flg_status%TYPE := 'A';
    g_flg_status_c drug_prescription.flg_status%TYPE := 'C';
    g_flg_status_e drug_prescription.flg_status%TYPE := 'E';
    g_flg_status_d drug_prescription.flg_status%TYPE := 'D';
    g_flg_status_i drug_prescription.flg_status%TYPE := 'I';

    g_flg_time_e drug_prescription.flg_time%TYPE := 'E';

    g_exam_req_pend exam_req.flg_status%TYPE := 'D';
    g_exam_req_req  exam_req.flg_status%TYPE := 'R';
    g_exam_req_exec exam_req.flg_status%TYPE := 'E';
    g_exam_req_part exam_req.flg_status%TYPE := 'P';
    g_exam_req_resu exam_req.flg_status%TYPE := 'F';
    g_exam_req_read exam_req.flg_status%TYPE := 'L';
    g_exam_req_canc exam_req.flg_status%TYPE := 'C';

    g_analy_req_pend analysis_req.flg_status%TYPE := 'D';
    g_analy_req_req  analysis_req.flg_status%TYPE := 'R';
    g_analy_req_exec analysis_req.flg_status%TYPE := 'E';
    g_analy_req_res  analysis_req.flg_status%TYPE := 'F';
    g_analy_req_read analysis_req.flg_status%TYPE := 'L';
    g_analy_req_canc analysis_req.flg_status%TYPE := 'C';
    g_analy_req_part analysis_req.flg_status%TYPE := 'P';
    g_analy_req_tran analysis_req.flg_status%TYPE := 'T';
    g_analy_req_harv analysis_req.flg_status%TYPE := 'H';

    g_yes VARCHAR2(1) := 'Y';
    g_no  VARCHAR2(1) := 'N';

    --pesquisas
    g_doc_active doc_external.flg_status%TYPE := 'A';

    g_sched_scheduled schedule_outp.flg_state%TYPE := 'A';

    g_discharge_status_active discharge.flg_status%TYPE := 'A';

    g_search_avail  sscr_crit.flg_available%TYPE;
    g_flg_mandatory sscr_crit.flg_mandatory%TYPE;

    g_domain_first_subs sys_domain.code_domain%TYPE;

    g_selected           VARCHAR2(1);
    g_flg_payment_domain VARCHAR2(200);
    g_flg_available      VARCHAR2(1);

    g_movem_term movement.flg_status%TYPE;

    --Complete non disclosure for VIP patients
    g_complete_non_disclosure patient.non_disclosure_level%TYPE := 'C';

END pk_information;
/
