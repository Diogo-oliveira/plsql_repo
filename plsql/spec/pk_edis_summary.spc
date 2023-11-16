/*-- Last Change Revision: $Rev: 2028664 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_summary AS
    /********************************************************************************************
    * Chama a função que constroi a string do estados dos workflows para ser utilizado numa grelha
    *
    * @param i_lang                 id da lingua
    * @param i_epis_status          estado do episódio
    * @param i_fgl_type
    * @param i_fgl_time             Realização: E - neste episódio; N - próximo episódio; B - entre episódios
    * @param i_fgl_status            Estado da requisição
    * @param i_dt_begin             Data pretendida para início da execução do exame (ie, ñ imediata)
    * @param i_dt_req               Data / hora de requisição
    * @param i_icon_name            Nome da imagem do estado da requisição
    *
    * @return                       true or false on success or error
    *
    * @author                       Rui Batista
    * @version                      1.0
    * @since                        2006/07/03
    ********************************************************************************************/
    FUNCTION get_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_epis_status IN episode.flg_status%TYPE,
        i_fgl_type    IN VARCHAR2,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_icon_name   IN VARCHAR2,
        i_rank        IN sys_domain.rank%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Obter a string constituída por: 1ª posição indica qual o ID do atalho
                                      2ª posição:D - é para fazer cálculos e apresentar tempo.
                                                 T - é para apresentar a mensagem AGENDADO e fazer cálculos caso a data esteja preenchida.
                                                 I - é para apresentar o ícone dos resultados.
                                      3ª posição: se a 2ª posição é D - data
                                                  se a 2ª posição é T - AGENDADO
                                                  se a 2ª posição é I - nome do ícone
    *
    * @param i_lang                 id da lingua
    * @param i_epis_status          estado do episódio
    * @param i_fgl_type             Tipo de grelha: D - Medicação; E - Exames; A - Analises; I - Procedimentos;
    * @param i_fgl_time             Realização: E - neste episódio; N - próximo episódio; B - entre episódios
    * @param i_fgl_status           Estado da requisição
    * @param i_dt_begin             Data pretendida para início da execução do exame (ie, ñ imediata)
    * @param i_dt_req               Data / hora de requisição
    * @param i_icon_name            Nome da imagem do estado da requisição
    * @param o_error                Error message
    *
    * @return                       true or false on success or error
    *
    * @author                       Emilia Taborda
    * @version                      1.0
    * @since                        2006/07/03
    ********************************************************************************************/
    FUNCTION get_edis_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_epis_status IN episode.flg_status%TYPE,
        i_fgl_type    IN VARCHAR2,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_icon_name   IN VARCHAR2,
        i_rank        IN sys_domain.rank%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Gets the data of critical care notes for the current episode 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             Identifier of Episode
    * @param O_CRIT_DATA              List with the critical care notes
    * @param O_ERROR                  Error message
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.1.2
    * @since                          07-Jul-2011
    *******************************************************************************************************************************************/
    FUNCTION get_critical_care_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_crit_data  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Listar os seguintes dados na página resumo
    *
    * @param i_lang                 id da lingua
    * @param i_epis                 id do episódio
    * @param i_prof                 id do profissional           
    * @param o_title_last_upd       título do último registo
    * @param o_last_update          último registo
    * @param o_title_complaint      título da queixa
    * @param o_complaint            queixa
    * @param o_vsignal              listar os últimos sinais vitais
    * @param o_title_history        título da história
    * @param o_history              listar history of present illness
    * @param o_title_review_sys     título do review of systems
    * @param o_review_system        listar os reviews of systems
    * @param o_title_pmhist         título para past medical history
    * @param o_past_med_hist        listar a past medical history
    * @param o_title_pshist         título para past surgical history
    * @param o_past_surg_hist       listar a past surgical history
    * @param o_allergies            listar as alergias
    * @param o_physical_exam        listar os exames físicos
    * @param o_diff_diagnosis       listar os diagnósticos diferenciais
    * @param o_interval_notes       listar a última nota intercalare
    * @param o_records_review       listar a última revisão de registo  
    * @param o_tests_review         listar a última revisão de exames e/ou análises
    * @param o_critical_care        listar última nota crítica
    * @param o_attending_notes      lista a última nota de atendimento
    * @param o_treatement_manag     listar a última nota de tratamento   
    * @param o_diagnosis            listar todos os diagnósticos finais
    * @param o_title_dispos         título da alta
    * @param o_disposition          listar a última alta
    * @param o_trauma_titles        ABCDE Assessment parameters labels
    * @param o_trauma               ABCDE Assessment data
    * @param o_nursing_assess       Nursing assessment last record 
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       Emilia Taborda
    * @version                      1.0   
    * @since                        2006/10/10
    ********************************************************************************************/
    FUNCTION get_summary_list
    (
        i_lang        IN language.id_language%TYPE,
        i_epis        IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_last_update OUT VARCHAR2,
        --
        o_title_complaint OUT VARCHAR2,
        o_complaint       OUT VARCHAR2,
        --
        o_title_chief_complaint OUT VARCHAR2,
        o_chief_complaint       OUT VARCHAR2,
        --
        o_title_vsignal OUT VARCHAR2,
        o_vsignal       OUT pk_types.cursor_type,
        --
        o_title_history OUT VARCHAR2,
        o_history       OUT pk_types.cursor_type,
        --
        o_title_review_sys OUT VARCHAR2,
        o_review_system    OUT pk_types.cursor_type,
        --
        o_title_pmhist  OUT VARCHAR2,
        o_past_med_hist OUT pk_types.cursor_type,
        --
        o_title_fam_hist OUT VARCHAR2,
        o_past_fam_hist  OUT pk_types.cursor_type,
        --
        o_title_soc_hist OUT VARCHAR2,
        o_past_soc_hist  OUT pk_types.cursor_type,
        --
        o_title_surg_hist OUT VARCHAR2,
        o_past_surg_hist  OUT pk_types.cursor_type,
        --
        o_title_allergies OUT VARCHAR2,
        o_allergies       OUT pk_types.cursor_type,
        --
        o_title_problems OUT VARCHAR2,
        o_problems       OUT pk_types.cursor_type,
        --
        o_title_habits OUT VARCHAR2,
        o_habits       OUT pk_types.cursor_type,
        --
        o_title_pmedicat OUT VARCHAR2,
        o_p_medication   OUT pk_types.cursor_type,
        --
        o_title_pexam   OUT VARCHAR2,
        o_physical_exam OUT pk_types.cursor_type,
        --
        o_title_passess  OUT VARCHAR2,
        o_nursing_assess OUT pk_types.cursor_type,
        --
        o_title_diff_diagnosis OUT VARCHAR2,
        o_diff_diagnosis       OUT pk_types.cursor_type,
        --
        o_title_interval_notes OUT VARCHAR2,
        o_interval_notes       OUT pk_types.cursor_type,
        --
        o_title_interval_notes_nur OUT VARCHAR2,
        o_interval_notes_nur       OUT pk_types.cursor_type,
        --
        o_title_interval_notes_tech OUT VARCHAR2,
        o_interval_notes_tech       OUT pk_types.cursor_type,
        --
        o_title_records_review OUT VARCHAR2,
        o_records_review       OUT pk_types.cursor_type,
        --
        o_title_tests_review OUT VARCHAR2,
        o_tests_review       OUT pk_types.cursor_type,
        --
        o_title_critical_care OUT VARCHAR2,
        o_critical_care       OUT pk_types.cursor_type,
        --
        o_title_attending_notes OUT VARCHAR2,
        o_attending_notes       OUT pk_types.cursor_type,
        --
        o_title_treatement_manag OUT VARCHAR2,
        o_treatement_manag       OUT pk_types.cursor_type,
        --
        o_title_diagnosis OUT VARCHAR2,
        o_diagnosis       OUT pk_types.cursor_type,
        --
        o_title_dispos OUT VARCHAR2,
        o_disposition  OUT pk_types.cursor_type,
        --
        o_title_trauma OUT pk_types.cursor_type,
        o_trauma       OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Data for medication, tests and imaging procedures, in order to fill in their grid Summary screen
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_ID_EPISODE               Episode ID associated 
    * @param   I_PROF                     professional, institution and software ids
    * @param   O_DRUG                     list od medication
    * @param   O_ANALY                    list of analysis 
    * @param   O_PROC                     list of procedures
    * @param   O_EXAM                     list of examinations
    * @param   O_DAYS_WARNING             message with the days that these list is filtering
    * @param   O_FLG_SHOW_WARNING         if INP/ORIS/EDIS/OUTP shows previous message otherwise not
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    *
    * @author  Emilia Taborda
    * @version 1.0
    * @since   03-JUL-2006
    * @notes   Each record can have a time remaining or that is in relation to the expected time of the drug administration. Beyond this time, also returns a flag: R - Fund in red. Administration in late G - Fund green. Administration scheduled for the future.
    *
    */
    FUNCTION get_summary_grid
    (
        i_lang             IN language.id_language%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        o_drug             OUT pk_types.cursor_type,
        o_analy            OUT pk_types.cursor_type,
        o_proc             OUT pk_types.cursor_type,
        o_exam             OUT pk_types.cursor_type,
        o_days_warning     OUT sys_message.desc_message%TYPE,
        o_flg_show_warning OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Listar todos os profissionais que realizaram revisão de registos,excepto o próprio profissional
    *
    * @param i_lang                        id language
    * @param i_rec_review                  ID da revisão de registo
    * @param i_prof                        professional, software and institution ids
    * @param i_epis                        episode id
    * @param o_error                       Error message
    *
    * @return                              true or false on success or error
    *
    * @author                              Emilia Taborda
    * @version                             1.0
    * @since                               2006/10/23
    **********************************************************************************************/
    FUNCTION get_all_prof_rec_review
    (
        i_lang       IN language.id_language%TYPE,
        i_rec_review IN records_review.id_records_review%TYPE,
        i_prof       IN profissional,
        i_epis       IN episode.id_episode%TYPE
    ) RETURN VARCHAR;

    /********************************************************************************************
    * Obter todas a história familiar e social de um paciente
    *
    * @param i_lang                        id language
    * @param i_prof                        professional, software and institution ids
    * @param i_patient                     patient id
    * @param o_pat_hist_fam_soc            Array para listar a história familiar e social de um dado paciente
    * @param o_error                       Error message
    *
    * @return                              true or false on success or error
    *
    * @author                              Emilia Taborda
    * @version                             1.0
    * @since                               2007/02/24
    **********************************************************************************************/
    FUNCTION get_pat_hist_fam_soc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        o_pat_hist_fam_soc OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obter todas as doenças relevantes(activas) de um paciente (concatenação)
    *
    * @param i_lang                        id language
    * @param i_patient                     patient id
    *
    * @return                              description
    *
    * @author                              Emilia Taborda
    * @version                             1.0
    * @since                               2007/02/25
    **********************************************************************************************/
    FUNCTION get_pat_problem
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR;

    /********************************************************************************************
    * Devolver as análises de um episódio 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_flg_stat_epis          State of episode
    * @param i_filter_tstz            Date to filter only the records with "end dates" > i_filter_tstz
    * @param i_filter_status          Array with task status to consider along with i_filter_tstz
    * @param o_analy                  Cursor containing the analysis of episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION get_summary_grid_analy
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_stat_epis IN episode.flg_status%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        o_analy         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolver os exames de imagem e outros de um episódio 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_flg_stat_epis          State of episode
    * @param i_filter_tstz            Date to filter only the records with "end dates" > i_filter_tstz
    * @param i_filter_status          Array with task status to consider along with i_filter_tstz
    * @param o_exam                   Cursor containing the imag exams and other exam of episode                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION get_summary_grid_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_stat_epis IN episode.flg_status%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        o_exam          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Devolver as intervenções de um episódio 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_flg_stat_epis          State of episode
    * @param i_filter_tstz            Date to filter only the records with "end dates" > i_filter_tstz
    * @param i_filter_status_prof     Array with task status to consider along with i_filter_tstz to the procedures registries
    * @param i_filter_status_nur      Array with task status to consider along with i_filter_tstz to the nurse_tea_req registries
    * @param i_filter_status_oris     Array with task status to consider along with i_filter_tstz to the oris procedures registries
    * @param o_proc                   Cursor containing the interventions of episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda
    * @version                        1.0   
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION get_summary_grid_proc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_stat_epis      IN episode.flg_status%TYPE,
        i_filter_tstz        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status_proc IN table_varchar,
        i_filter_status_nur  IN table_varchar,
        i_filter_status_oris IN table_varchar,
        o_proc               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get list of images and other exams for a given id_visit
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_visit               the id visit
    * @param i_epis_type              Type of episode
    * @param i_filter_tstz            Date to filter only the records with "end dates" > i_filter_tstz
    * @param i_filter_status          Array with task status to consider along with i_filter_tstz
    *
    * @return                         return list of images and other exams
    *
    * @author                         Filipe Silva
    * @version                        2.5.0.7.7
    * @since                          2010/02/23
    **********************************************************************************************/
    FUNCTION tf_summary_grid_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_visit      IN episode.id_visit%TYPE,
        i_epis_type     IN epis_type.id_epis_type%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar
    ) RETURN t_table_summary_grid_exam;

    /********************************************************************************************
    * Get list of analysis for a given id_visit
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_visit               the id visit
    * @param i_epis_type              Type of episode
    * @param i_filter_tstz            Date to filter only the records with "end dates" > i_filter_tstz
    * @param i_filter_status          Array with task status to consider along with i_filter_tstz
    *
    * @return                         return list of analysis
    *
    * @author                         Filipe Silva
    * @version                        2.5.0.7.7
    * @since                          2010/02/23
    **********************************************************************************************/

    FUNCTION tf_summary_grid_analy
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_visit      IN episode.id_visit%TYPE,
        i_epis_type     IN epis_type.id_epis_type%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar
    ) RETURN t_table_summary_grid_analy;

    /**######################################################
      GLOBAIS
    ######################################################**/
    g_error        VARCHAR2(4000);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    g_exception EXCEPTION;

    g_soft_care CONSTANT software.code_software%TYPE := 3;
    g_soft_edis CONSTANT software.code_software%TYPE := 8;
    g_soft_inp  CONSTANT software.code_software%TYPE := 11;
    g_soft_ubu  CONSTANT software.code_software%TYPE := 29;

    g_epis_type_consult CONSTANT epis_type.id_epis_type%TYPE := 1;
    g_epis_type_edis    CONSTANT epis_type.id_epis_type%TYPE := 2;
    g_epis_type_inp     CONSTANT epis_type.id_epis_type%TYPE := 5;
    g_epis_type_ubu     CONSTANT epis_type.id_epis_type%TYPE := 9;
    g_epis_type_urg     CONSTANT epis_type.id_epis_type%TYPE := 2;

    g_cat_doctor CONSTANT category.flg_type%TYPE := 'D';
    g_cat_nurse  CONSTANT category.flg_type%TYPE := 'N';

    g_cancelled CONSTANT VARCHAR2(1) := 'C';

    g_icon        VARCHAR2(1);
    g_no_color    VARCHAR2(1);
    g_color_red   VARCHAR2(1);
    g_color_green VARCHAR2(1);

    g_cancel        VARCHAR2(1);
    g_cancel_u      VARCHAR2(1);
    g_resolved      VARCHAR2(1);
    g_epis_inactive episode.flg_status%TYPE;
    g_active        episode.flg_status%TYPE;

    g_flg_status_x     VARCHAR2(1);
    g_flg_status_pa    VARCHAR2(2);
    g_flg_status_a     VARCHAR2(1);
    g_flg_status_r     VARCHAR2(1);
    g_flg_status_d     VARCHAR2(1);
    g_flg_status_e     VARCHAR2(1);
    g_flg_status_ex    VARCHAR2(2);
    g_flg_status_cc    VARCHAR2(2);
    g_flg_status_h     VARCHAR2(1);
    g_flg_status_t     VARCHAR2(1);
    g_flg_status_end_t VARCHAR2(1);
    g_flg_status_p     VARCHAR2(1);
    g_flg_status_f     VARCHAR2(1);
    g_flg_status_l     VARCHAR2(1);
    g_flg_status_s     VARCHAR2(1);
    g_flg_status_i     VARCHAR2(1);
    g_flg_status_c     VARCHAR2(1);

    g_text  VARCHAR2(1);
    g_date  VARCHAR2(1);
    g_read  VARCHAR2(1);
    g_label VARCHAR2(1);

    g_flg_type_d VARCHAR2(1);
    g_flg_type_e VARCHAR2(1);
    g_flg_type_a VARCHAR2(1);
    g_flg_type_i VARCHAR2(1);
    g_flg_type_o VARCHAR2(1);

    -- ICONES
    g_icon_r VARCHAR2(200); -- Requesitado
    g_icon_d VARCHAR2(200); -- Pendente
    g_icon_e VARCHAR2(200); -- Em execução
    g_icon_t VARCHAR2(200); -- Em transporte
    g_icon_f VARCHAR2(200); -- Terminado (concluído)
    g_icon_l VARCHAR2(200); -- Lido

    g_interv_plan_admt  interv_presc_plan.flg_status%TYPE;
    g_interv_plan_nadmt interv_presc_plan.flg_status%TYPE;
    g_interv_plan_req   interv_presc_plan.flg_status%TYPE;
    g_interv_plan_pend  interv_presc_plan.flg_status%TYPE;
    g_interv_plan_canc  interv_presc_plan.flg_status%TYPE;

    g_interv_type_nor interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_sos interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_uni interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_ete interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_con interv_presc_det.flg_interv_type%TYPE;

    g_complaint_act epis_complaint.flg_status%TYPE;
    g_epis_anam_active CONSTANT epis_anamnesis.flg_status%TYPE := 'A';

    g_pat_hist_diag_type_med CONSTANT pat_history_diagnosis.flg_type%TYPE := 'M';

    g_diag_type_p      epis_diagnosis.flg_type%TYPE;
    g_diag_type_d      epis_diagnosis.flg_type%TYPE;
    g_diag_type_b      epis_diagnosis.flg_type%TYPE;
    g_ed_flg_status_d  epis_diagnosis.flg_status%TYPE;
    g_ed_flg_status_co epis_diagnosis.flg_status%TYPE;

    g_available records_review.flg_available%TYPE;

    g_flg_type_c critical_care.flg_type%TYPE;
    g_flg_type_h critical_care.flg_type%TYPE;

    g_exam_status_final exam_req_det.flg_status%TYPE;
    g_exam_status_read  exam_req_det.flg_status%TYPE;

    g_analisys_status_final analysis_req_det.flg_status%TYPE;
    g_analisys_status_red   analysis_req_det.flg_status%TYPE;
    g_exam_can_req          exam_dep_clin_serv.flg_type%TYPE;

    g_tests_type_exam     tests_review.flg_type%TYPE;
    g_tests_type_analisys tests_review.flg_type%TYPE;
    g_tests_type_result   tests_review.flg_type%TYPE;

    g_treat_type_interv treatment_management.flg_type%TYPE;
    g_treat_type_drug   treatment_management.flg_type%TYPE;

    g_interv_status_final interv_presc_det.flg_status%TYPE;
    g_interv_status_curso interv_presc_det.flg_status%TYPE;
    g_interv_status_inter interv_presc_det.flg_status%TYPE;

    g_allergies_stat pat_allergy.flg_status%TYPE;

    g_vs_rel_conc    vital_sign_relation.relation_domain%TYPE;
    g_vs_rel_sum     vital_sign_relation.relation_domain%TYPE;
    g_vs_rel_man     vital_sign_relation.relation_domain%TYPE;
    g_vs_read_active vital_sign_read.flg_state%TYPE;
    g_vs_read_cancel vital_sign_read.flg_state%TYPE;

    g_vs_avail          vital_sign.flg_available%TYPE;
    g_epis_document_act epis_documentation.flg_status%TYPE;

    g_criteria VARCHAR2(20);

    g_icon_name VARCHAR2(20);

    -- DOCUMENTATION
    g_area_complaint          doc_area.id_doc_area%TYPE;
    g_area_history            doc_area.id_doc_area%TYPE;
    g_area_review_system      doc_area.id_doc_area%TYPE;
    g_area_past_med_hist      doc_area.id_doc_area%TYPE;
    g_area_past_f_social_hist doc_area.id_doc_area%TYPE;
    g_area_physical_exam_d    doc_area.id_doc_area%TYPE;
    g_area_physical_exam_n    doc_area.id_doc_area%TYPE;

    g_rreview_read_stat records_review_read.flg_status%TYPE;
    g_flg_time_next     analysis_req.flg_time%TYPE;

    g_documentation sys_config.value%TYPE;
    g_document_n    sys_config.value%TYPE;
    g_document_d    sys_config.value%TYPE;
    g_switch_mode   sys_config.value%TYPE;

    g_flg_temp epis_anamnesis.flg_temp%TYPE;
    g_flg_def  epis_anamnesis.flg_temp%TYPE;

    g_software_oris CONSTANT software.id_software%TYPE := 2;
    g_software_outp CONSTANT software.id_software%TYPE := 1;
    g_software_care CONSTANT software.id_software%TYPE := 3;
    g_software_pp   CONSTANT software.id_software%TYPE := 12;
    g_soft_nutri    CONSTANT software.id_software%TYPE := 43;
    g_anam_flg_type_c epis_anamnesis.flg_type%TYPE;
    g_anam_flg_type_a epis_anamnesis.flg_type%TYPE;
    g_pat_hfam_type   pat_fam_soc_hist.flg_type%TYPE;
    g_pat_hsoc_type   pat_fam_soc_hist.flg_type%TYPE;

    g_exam_type     exam.flg_type%TYPE;
    g_exam_type_img exam.flg_type%TYPE;
    g_flg_temp_d    epis_anamnesis.flg_temp%TYPE;
    g_flg_temp_t    epis_anamnesis.flg_temp%TYPE;

    g_pat_history_diagnosis_n CONSTANT VARCHAR2(1) := 'N';

    g_analysis_type_req     VARCHAR2(2);
    g_analysis_type_req_det VARCHAR2(2);
    g_analysis_type_harv    VARCHAR2(2);

    g_exam_type_req ti_log.flg_type%TYPE := 'ER';
    g_exam_type_det ti_log.flg_type%TYPE := 'ED';

    g_ti_log_interv    ti_log.flg_type%TYPE := 'PR';
    g_ti_log_nurse_tea ti_log.flg_type%TYPE := 'NT';

    g_flg_status            CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET.FLG_STATUS_MFR';
    g_flg_status_change     CONSTANT sys_domain.code_domain%TYPE := 'INTERV_PRESC_DET_CHANGE.FLG_STATUS_CHANGE';
    g_flg_referral_reserved CONSTANT interv_presc_det.flg_referral%TYPE := 'R';
    g_flg_referral_sent     CONSTANT interv_presc_det.flg_referral%TYPE := 'S';

    g_shortcut_procedures    CONSTANT VARCHAR2(1) := '7';
    g_shortcut_proc_mfr      CONSTANT VARCHAR2(4) := '1659';
    g_shortcut_teach         CONSTANT VARCHAR2(2) := '15';
    g_shortcut_pat_education CONSTANT VARCHAR2(6) := '900708';

    g_nutritionist_profile    CONSTANT NUMBER(3) := 70;
    g_presc_nurse_profile     CONSTANT NUMBER(3) := 119;
    g_presc_physician_profile CONSTANT NUMBER(3) := 120;
    g_default_shortcut        CONSTANT VARCHAR2(1) := '0';

    g_summary_filter     CONSTANT sys_message.code_message%TYPE := 'SUMMARY_CLOSED_TASK_FILTER_DESC';
    g_summary_filter_one CONSTANT sys_message.code_message%TYPE := 'SUMMARY_CLOSED_TASK_FILTER_DESC_ONE';

    -- closed task filter interval in days
    g_cfg_closed_task_filter CONSTANT sys_config.id_sys_config%TYPE := 'SUMMARY_CLOSED_TASK_FILTER_INTERVAL';

    g_yes CONSTANT VARCHAR2(1) := 'Y';

    -- constants to the summary grids
    g_medication_status CONSTANT table_varchar := table_varchar('W', 'I', 'C', 'F');
    g_exam_status       CONSTANT table_varchar := table_varchar(pk_alert_constant.g_exam_req_result,
                                                                pk_alert_constant.g_exam_req_read);
    g_analysis_status   CONSTANT table_varchar := table_varchar(pk_alert_constant.g_analysis_det_result,
                                                                pk_alert_constant.g_analysis_det_read);
    g_procedures_status CONSTANT table_varchar := table_varchar('F', 'I');
    g_nursing_status    CONSTANT table_varchar := table_varchar('F');

    g_list_ivfluids          CONSTANT VARCHAR2(13) := 'LIST_IVFLUIDS';
    g_list_drug              CONSTANT VARCHAR2(9) := 'LIST_DRUG';
    g_grid_oth_exam          CONSTANT VARCHAR2(13) := 'GRID_OTH_EXAM';
    g_grid_image             CONSTANT VARCHAR2(10) := 'GRID_IMAGE';
    g_grid_analysis          CONSTANT VARCHAR2(13) := 'GRID_ANALYSIS';
    g_grid_harvest           CONSTANT VARCHAR2(12) := 'GRID_HARVEST';
    g_list_proc              CONSTANT VARCHAR2(9) := 'LIST_PROC';
    g_list_nurse_teach       CONSTANT VARCHAR2(16) := 'LIST_NURSE_TEACH';
    g_sr_clin_inf_sum_posit  CONSTANT VARCHAR2(30) := 'SR_CLINICAL_INFO_SUMMARY_POSIT';
    g_sr_clin_inf_sum_dr_pr  CONSTANT VARCHAR2(35) := 'SR_CLINICAL_INFO_SUMMARY_DRUG_PRESC';
    g_sr_clin_inf_sum_int_pr CONSTANT VARCHAR2(37) := 'SR_CLINICAL_INFO_SUMMARY_INTERV_PRESC';
    g_ivfluids_list          CONSTANT VARCHAR2(13) := 'IVFLUIDS_LIST';
    g_grid_proc              CONSTANT VARCHAR2(9) := 'GRID_PROC';
    g_grid_teach             CONSTANT VARCHAR2(18) := 'GRID_PAT_EDUCATION';
    g_grid_drug_admin        CONSTANT VARCHAR2(15) := 'GRID_DRUG_ADMIN';

END pk_edis_summary;
/
