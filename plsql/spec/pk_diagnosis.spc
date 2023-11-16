/*-- Last Change Revision: $Rev: 2047268 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-10-12 14:49:22 +0100 (qua, 12 out 2022) $*/

CREATE OR REPLACE PACKAGE pk_diagnosis AS
    --
    g_code_domain_yes_no CONSTANT sys_domain.code_domain%TYPE := 'YES_NO';
    g_code_column_name   CONSTANT VARCHAR2(200) := 'DIAGNOSIS.CODE_DIAGNOSIS OR ALERT_DIAGNOSIS.CODE_ALERT_DIAGNOSIS OR CONCEPT_TERM.CODE_CONCEPT_TERM';
    --
    g_check_type_prim_diag CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_check_type_all       CONSTANT VARCHAR2(1 CHAR) := 'A';
    --
    g_ed_flg_status_ca CONSTANT epis_diagnosis.flg_status%TYPE := 'C'; -- cancelar
    g_ed_flg_status_d  CONSTANT epis_diagnosis.flg_status%TYPE := 'D'; --despiste(ampulheta)
    g_ed_flg_status_co CONSTANT epis_diagnosis.flg_status%TYPE := 'F'; --confirmar
    g_ed_flg_status_r  CONSTANT epis_diagnosis.flg_status%TYPE := 'R'; --declinar(-)
    g_ed_flg_status_b  CONSTANT epis_diagnosis.flg_status%TYPE := 'B'; --Diagnóstico base
    g_ed_flg_status_p  CONSTANT epis_diagnosis.flg_status%TYPE := 'P'; --Presumido

    /**********************************************************************************************
    * Get diagnosis description from an episode diagnosis
    *
    * @param i_lang                   the id language
    * @param i_diagnosis              diagnosis to get description
    * @param i_alert_diagnosis        alert diagnosis to get description
    * @param i_desc_epis_diagnosis    description of diagnosis in epis_diagnosis
    *
    * @return                         diagnosis description
    *                        
    * @author                         Daniel Ferreira
    * @version                        1.0 
    * @since                          2014/10/09
    **********************************************************************************************/
    FUNCTION coding_get_diag_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_desc_epis_diag  IN epis_diagnosis.desc_epis_diagnosis%TYPE
    ) RETURN VARCHAR2;

    FUNCTION coding_get_diag_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Obter os diagnósticos +  frequentes de um prof. e do dep. + serv clínico a que est?associado (DIFERENCIAIS)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_epis                   episode id
    * @param o_diagnosis              array with diagnosis
    * @param o_epis_diagnosis         array with diagnosis of episode
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/10
    **********************************************************************************************/
    FUNCTION get_freq_diag_diff
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_diagnosis      OUT pk_types.cursor_type,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter os diagnósticos +  frequentes de um prof. e do dep. + serv clínico a que est?associado (FINAIS)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_epis                   episode id
    * @param o_diagnosis              array with diagnosis
    * @param o_epis_diagnosis         array with diagnosis of episode
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/10
    **********************************************************************************************/
    FUNCTION get_freq_diag_final
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_diagnosis      OUT pk_types.cursor_type,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter os diagnósticos diferenciais(provisórios) associados ao template da queixa(activa) do episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param o_title                  Descrição da queixa seleccionada                  
    * @param o_diagnosis              array with diagnosis
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/02
    **********************************************************************************************/
    FUNCTION get_complaint_diag_diff_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_title     OUT pk_types.cursor_type,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar todos os estados / icones de cada estado dos diagnósticos diferenciais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_status                 array with status of differencial diagnosis
    * @param o_assoc_prob             Associated problem list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/02
    **********************************************************************************************/
    FUNCTION get_epis_diag_status_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_status     OUT pk_types.cursor_type,
        o_assoc_prob OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get diagnosis description (having in consideration that it can be an episode diagnosis)
    *
    * @param    i_lang         preferred language ID
    * @param    i_prof         object (id of professional, id of institution, id of software)
    * @param    i_episode      episode ID
    * @param    i_diagnosis    diagnosis ID
    * @param    i_alert_diagnosis  alert diagnosis ID    
    *
    * @return   varchar2       diagnosis description
    *
    * @author   Tiago Silva
    * @since    2010/08/06
    ********************************************************************************************/
    FUNCTION get_epis_diag_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation;
    --
    /**********************************************************************************************
    * Listar todos os diagnósticos diferenciais provisórios do episódio
    * Nota: Invocada exclusivamente pelo JAVA
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_prof_cat_type          categoty of professional
    * @param o_list                   Listar todos os diagnósticos diferenciais provisórios do episódio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/05
    **********************************************************************************************/
    FUNCTION get_diag_diff_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar todos os diagnósticos diferenciais do paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                Patient ID
    * @param i_prof_cat_type          categoty of professional
    * @param o_list                   Listar todos os diagnósticos diferenciais provisórios do episódio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/05
    **********************************************************************************************/
    FUNCTION get_diag_diff_pat_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar os diagnósticos definitivos do episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_prof_cat_type          categoty of professional
    * @param o_final                   Listar todos os diagnósticos definitivos do episódio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_final_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_final         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_count_final_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Listar os diagnósticos diferenciais(provisórios) confirmados e em despiste do episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param o_title                  Título com a queixa do episódio
    * @param o_differ                 Listar os diagnósticos diferenciais(provisórios) confirmados e em despiste do episódio
    * @param o_diag_complaint         Diagnosis associated with the current complaint
    * @param o_past_med_hist          Past medical history
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_diag_differential
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        o_title          OUT pk_types.cursor_type,
        o_differ         OUT pk_types.cursor_type,
        o_diag_complaint OUT pk_types.cursor_type,
        o_past_med_hist  OUT pk_summary_page.doc_area_val_past_med_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Get home table function 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis                 episode identifier
    *
    * @return                         pipelined table
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_associated_diagnosis_tf
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_epis                   IN episode.id_episode%TYPE,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_coll_diagnosis_config;

    FUNCTION get_associated_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        o_differ OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_mcdt_req_diagnosis
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis             IN episode.id_episode%TYPE,
        i_diag             IN table_number,
        i_desc_diagnosis   IN table_varchar,
        i_exam_req         IN exam_req.id_exam_req%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc     IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diag              IN table_number,
        i_desc_diagnosis    IN table_varchar,
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diag              IN CLOB,
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diag              IN pk_edis_types.rec_in_epis_diagnosis,
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE DEFAULT NULL,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_mcdt_req_diag_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_diagnosis         IN pk_edis_types.rec_in_epis_diagnosis,
        i_exam_req          IN exam_req.id_exam_req%TYPE,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        i_interv_presc      IN interv_prescription.id_interv_prescription%TYPE,
        i_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE DEFAULT NULL,
        i_epis_comp_hist    IN epis_comp_hist.id_epis_comp_hist%TYPE DEFAULT NULL,
        i_nurse_tea_req     IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result       IN mcdt_req_diagnosis.id_exam_result%TYPE DEFAULT NULL,
        i_epis_diag_status  IN epis_diagnosis.flg_status%TYPE DEFAULT g_ed_flg_status_d,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE DEFAULT NULL,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_rehab_presc_hist  IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL,
        i_dt_tstz           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION concat_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_exam_req_det           IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det       IN interv_presc_det.id_interv_presc_det%TYPE,
        i_prof                   IN profissional,
        i_nurse_tea_req          IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result            IN exam_result.id_exam_result%TYPE DEFAULT NULL,
        i_blood_product_det      IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc            IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Listar os estados / icones disponiveis no momento da criação
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_flg_type               Tipo de diagnóstico (diferencial ou final)
    * @param o_status                 Lista dos estados dos diagnósticos diferenciais
    * @param o_assoc_prob             Associated problem list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda e Luis Oliveira
    * @version                        1.0 
    * @since                          2007/02/11
    **********************************************************************************************/
    FUNCTION get_epis_diag_stat_new_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE,
        o_status     OUT pk_edis_types.cursor_status,
        o_assoc_prob OUT pk_edis_types.cursor_assoc_prob,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter os diagnósticos diferenciais do episódio que ainda não são diagnósticos finais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_epis_diag              diagnosis episode id    
    * @param o_epis_diag_det          Lista dos diagnósticos diferenciais ou finais de um episódio
    * @param o_lab_tests              Lista de analises  associadas ao diagnóstico
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_epis_diag     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_epis_diag_det OUT pk_types.cursor_type,
        o_lab_tests     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter o último diagnósticos diferencial do episódio que ainda não são diagnósticos finais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_epis_diag              diagnosis episode id    
    * @param o_epis_diag_det_last     Último diagnósticos diferencial de um episódio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Filipe Machado
    * @version                        1.0 
    * @since                          2009/04/30
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_det_last
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis               IN episode.id_episode%TYPE,
        i_epis_diag          IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_epis_diag_det_last OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Lista de diagnósticos definitivos de episódios anteriores do paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_episode                episode id
    * @param i_flag_filter            Filtro a aplicar: A - (all) mostrar todos os diagnósticos anteriores
                                                        L - (last) mostrar apenas o último diagnóstico anterior
                                                        MA - (my all) mostrar todos os diagnósticos anteriores criados por um determinado profissional
                                                        ML - (my last) mostrar apenas o último diagnóstico anterior criado por um determinado profissional
    * @param o_epis_diag_prev         Lista de diagnósticos definitivos de episódios anteriores do paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_prev
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flag_filter    IN VARCHAR2,
        o_epis_diag_prev OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter os descritivos dos MCDTs associados a um diagnóstico
    *
    * @param i_lang                   the id language
    * @param i_code                   ID do MCDT    
    * @param i_flag_type              Tipo de MCDT: A - Análises; E - Exames; I - Intervenções
    * @param i_epis_diag              diagnosis episode id
    *
    * @return                         Lista de MCDTs concatenados com ponto e virgula
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION concat_mcdts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flag_type IN VARCHAR2,
        i_epis_diag IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Obter os descritivos dos MCDTs associados a um diagnóstico
    *
    * @param i_lang                   the id language
    * @param i_code                   ID do MCDT    
    * @param i_flag_type              Tipo de MCDT: A - Análises; E - Exames; I - Intervenções
    *
    * @return                         Lista de MCDTs concatenados com ponto e virgula
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION concat_mcdts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_diag IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flag_type IN VARCHAR2
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Lista o estados de um diagnóstico associado a um episódio
    *
    * @param i_epis                   episode id    
    * @param i_diagnosis              diagnosis id
    *
    * @return                         diagnosis status 
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/16
    **********************************************************************************************/
    FUNCTION get_status_diag
    (
        i_epis      IN epis_diagnosis.id_episode%TYPE,
        i_diagnosis IN epis_diagnosis.id_diagnosis%TYPE,
        i_diag_type IN epis_diagnosis.flg_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Lista dos tipos dos diagnósticos diferenciais
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_type                   Lista dos tipos dos diagnósticos diferenciais
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/19
    **********************************************************************************************/
    FUNCTION get_epis_diag_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * builds a standard formatted diagnosis description that is displayed to the user (with or without code and synonym indication)
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    * @param i_flg_add_cause           Add diagnosis cause info (ALERT-261232)
    * @param i_flg_show_ae_diag_info   Is to concatenate all AE diagnoses info?
    * @param i_ed_rowtype              Row type sent in Global search trigger
    * @param i_flg_show_if_principal   Show 'Principal diagnosis' when aplicable, i_show_aditional_info as to be 'Y'
    *
    * @return                 formatted text containing the diagnosis description
    *
    * @author                 Sergio Dias
    * @version                2.0
    * @since                  7/Fev/2012
    **********************************************************************************************/
    FUNCTION std_diag_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_alert_diagnosis    IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis          IN diagnosis.id_diagnosis%TYPE DEFAULT NULL,
        i_code_diagnosis        IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language    IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type          IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis   IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                  IN diagnosis.code_icd%TYPE,
        i_flg_other             IN diagnosis.flg_other%TYPE,
        i_flg_std_diag          IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag             IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_show_aditional_info   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_past_hist         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_term_code    IN VARCHAR2 DEFAULT NULL,
        i_flg_add_cause         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_ae_diag_info IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_ed_rowtype            IN epis_diagnosis%ROWTYPE DEFAULT NULL,
        i_flg_show_if_principal IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_dt_initial   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_status            IN VARCHAR2 DEFAULT NULL,
        i_flg_type              IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * builds a standard formatted description for the staging basis
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    * @param i_format_bold             Formats the staging description to bold: (Y)es or (N)o
    * @param i_staging_basis_type      Checks the type of staging in order to show the staging index
    * @param i_num_staging_basis       Staging index
    * @param i_show_full_desc          Shows the staging fully specified name: (Y)es or (N)o
    *
    * @return                 formatted text containing the staging basis description
    * 
    * @author                 Jos?Silva
    * @version                2.6.2.1
    * @since                  18/Mar/2012
    **********************************************************************************************/
    FUNCTION std_staging_basis_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_alert_diagnosis  IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis        IN diagnosis.id_diagnosis%TYPE DEFAULT NULL,
        i_code_diagnosis      IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language  IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                IN diagnosis.code_icd%TYPE,
        i_flg_other           IN diagnosis.flg_other%TYPE,
        i_flg_std_diag        IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag           IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_past_hist       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_format_bold         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_staging_basis_type  IN VARCHAR2 DEFAULT NULL,
        i_num_staging_basis   IN epis_diag_stag.num_staging_basis%TYPE DEFAULT NULL,
        i_show_full_desc      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * builds a standard formatted description for the tnm fields
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    * @param i_format_bold             Formats the staging description to bold: (Y)es or (N)o
    * @param i_code_staging            Staging code
    *
    * @return                 formatted text containing the tnm description
    * 
    * @author                 Jos?Silva
    * @version                2.6.2.1
    * @since                  18/Mar/2012
    **********************************************************************************************/
    FUNCTION std_tnm_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_alert_diagnosis  IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis        IN diagnosis.id_diagnosis%TYPE DEFAULT NULL,
        i_code_diagnosis      IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language  IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                IN diagnosis.code_icd%TYPE,
        i_flg_other           IN diagnosis.flg_other%TYPE,
        i_flg_std_diag        IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag           IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_past_hist       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_format_bold         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_code_staging        IN diagnosis.code_icd%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * builds a standard formatted description for the staging basis field
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      Alert Diagnosis ID
    * @param i_id_diagnosis            Diagnosis ID
    * @param i_code_diagnosis          Diagnosis Code
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Functional area from where the translation was requested. 
    * @param i_desc_epis_diagnosis     Diagnosis Free-text description
    * @param i_code                    Diagnosis code
    * @param i_flg_other               flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag            flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag               When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist           Flag used to include past history info
    * @param i_flg_search_mode         Flag to indicate if this is a search mode query
    *
    * @return                 formatted text containing the tnm description
    * 
    * @author                 Jos?Silva
    * @version                2.6.2.1
    * @since                  27/Mar/2012
    **********************************************************************************************/
    FUNCTION std_diag_basis_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_alert_diagnosis  IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_id_diagnosis        IN diagnosis.id_diagnosis%TYPE,
        i_code_diagnosis      IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language  IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type        IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_desc_epis_diagnosis IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_code                IN diagnosis.code_icd%TYPE,
        i_flg_other           IN diagnosis.flg_other%TYPE,
        i_flg_std_diag        IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag           IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_past_hist       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Altera o estado de um problema que est?associado a um diagnóstico
      Esta função deixou de ser usada, agora elimina-se o problema em vez de alterar o seu estado
    *
    * @param i_lang                   ID da língua
    * @param i_prof                   Objecto (id do profissional, id da instituição, id do software)
    * @param i_epis                   ID do episódio
    * @param i_epis_diag              ID do diagnóstico associado ao episódio
    * @param i_flg_status             Novo estado do problema
    * @param o_error                  Error message
    * 
    * @return                         true or false para sucesso ou erro
    * 
    * @author                         Luis Oliveira
    * @version                        1.0   
    * @since                          2007/06/20
    **********************************************************************************************/
    FUNCTION set_prob_assoc_diag_status_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis       IN episode.id_episode%TYPE,
        i_epis_diag  IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_status IN pat_problem.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /** @headcom
    * Public Function. Obter os id's dos diagnósticos associados a uma requisição.
    * Não ?chamada pelo Flash.
    *
    * @param      I_LANG               Língua registada como preferência do profissional
    * @param      I_EXAM_REQ     ID da requisição de exames.
    * @param      I_ANALYSIS_REQ   ID da requisição de análises.
    * @param      I_INTERV_PRESC   ID da requisição de procedimentos.
    * @param      I_PROF         object (ID do profissional, ID da instituição, ID do software)
    *
    * @return     boolean
    * @author     Gustavo Serrano
    * @version    0.1
    * @since      2008/05/27
    */
    FUNCTION concat_diag_id_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_exam_req_det           IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det       IN interv_presc_det.id_interv_presc_det%TYPE,
        i_prof                   IN profissional,
        i_type                   IN VARCHAR2,
        i_nurse_tea_req          IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result            IN exam_result.id_exam_result%TYPE DEFAULT NULL,
        i_blood_product_det      IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc            IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    FUNCTION concat_diag_hist_id_str
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_type               IN VARCHAR2,
        i_nurse_tea_req_hist IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /** @headcom
    * Public Function. Obter os id's dos diagnósticos associados a uma requisição.
    * Não ?chamada pelo Flash.
    *
    * @param      I_LANG               Língua registada como preferência do profissional
    * @param      I_EXAM_REQ     ID da requisição de exames.
    * @param      I_ANALYSIS_REQ   ID da requisição de análises.
    * @param      I_INTERV_PRESC   ID da requisição de procedimentos.
    * @param      I_PROF         object (ID do profissional, ID da instituição, ID do software)
    *
    * @return     boolean
    * @author     Gustavo Serrano
    * @version    0.1
    * @since      2008/05/27
    */
    FUNCTION concat_diag_id
    (
        i_lang                   IN language.id_language%TYPE,
        i_exam_req_det           IN exam_req_det.id_exam_req_det%TYPE,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_interv_presc_det       IN interv_presc_det.id_interv_presc_det%TYPE,
        i_prof                   IN profissional,
        i_type                   IN VARCHAR2,
        i_nurse_tea_req          IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL,
        i_exam_result            IN exam_result.id_exam_result%TYPE DEFAULT NULL,
        i_blood_product_det      IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_rehab_presc            IN rehab_presc.id_rehab_presc%TYPE DEFAULT NULL,
        i_show_aditional_info    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN table_varchar;

    FUNCTION concat_diag_hist_id
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_type               IN VARCHAR2,
        i_nurse_tea_req_hist IN nurse_tea_req.id_nurse_tea_req%TYPE DEFAULT NULL
    ) RETURN table_varchar;

    /** @headcom
    * Public Function. Obter os id's dos diagnósticos associados a uma requisição.
    * Não ?chamada pelo Flash.
    *
    * @param      I_LANG               Língua registada como preferência do profissional
    * @param      I_EXAM_REQ     table_number of ID da requisição de exames.
    * @param      I_ANALYSIS_REQ   table_number of ID da requisição de análises.
    * @param      I_INTERV_PRESC   table_number of ID da requisição de procedimentos.
    * @param      I_PROF         object (ID do profissional, ID da instituição, ID do software)
    *
    * @return     boolean
    * @author     Gustavo Serrano
    * @version    0.1
    * @since      2009/04/26
    */
    FUNCTION concat_diag_id
    (
        i_lang              IN language.id_language%TYPE,
        i_exam_req_det      IN table_number,
        i_analysis_req_det  IN table_number,
        i_interv_presc_det  IN table_number,
        i_prof              IN profissional,
        i_type              IN VARCHAR2,
        i_nurse_tea_req     IN table_number DEFAULT NULL,
        i_exam_result       IN table_number DEFAULT NULL,
        i_blood_product_det IN table_number DEFAULT NULL,
        i_rehab_presc       IN table_number DEFAULT NULL
    ) RETURN table_varchar;

    /********************************************************************************************
    * Function that returns diagnosis for an episode
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             episode ID
    *
    * @param o_diag                   Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Jos?Silva
    * @version                        2.6.1.2
    * @since                          2011/08/16
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns diagnosis for an episode array
    * Note : used in admission surgery request functionality
    * Based in get_epis_diag function
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             Array of episode ID
    *
    * @param o_diag                   Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Filipe Silva
    * @version                        2.5.1.5  
    * @since                          2011/03/31
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_diag       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that includes all business rules related to diagnosis episode match
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_new_epis               New episode ID
    * @param i_old_epis               Old episode ID
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          2009/07/09
    **********************************************************************************************/
    FUNCTION set_match_diagnosis
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_new_epis IN episode.id_episode%TYPE,
        i_old_epis IN episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the user must be warned about the current diagnosis creation/edition
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diagnosis         diagnosis record associated to the episode (when editing a diagnosis)
    * @param i_check_type             type of check: P - primary, A - all
    * @param i_flg_final_type         diagnosis type: P - primary, S - secondary
    * @param i_sub_analysis           sub analysis id
    * @param i_anatomical_area        anatomical area id
    * @param i_anatomical_side        anatomical side id
    * @param o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param o_msg                    Warning message
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          2009/09/07
    **********************************************************************************************/
    FUNCTION check_primary_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diagnosis  IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_check_type      IN VARCHAR2 DEFAULT g_check_type_prim_diag,
        i_flg_final_type  IN table_varchar,
        i_diagnosis       IN table_number,
        i_sub_analysis    IN table_number,
        i_anatomical_area IN table_number,
        i_anatomical_side IN table_number,
        i_rank            IN table_number DEFAULT NULL,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    -- verifies if selected diagnosis is a complication of another diagnosis
    **********************************************************************************************/
    FUNCTION check_diag_is_complication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis   IN table_number,
        i_desc_diagnosis IN table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION check_dup_diag_complication
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diagnosis_list      IN table_number,
        i_desc_diagnosis_list    IN table_varchar,
        i_id_complications_list  IN table_number,
        i_desc_complication_list IN table_varchar,
        o_flg_show               OUT VARCHAR2,
        o_msg                    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION check_dup_icd_diag
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    **********************************************************************************************/
    FUNCTION check_dup_rank
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_rank_list IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the information of diagnoses of the provided episode.
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID    
    *
    * @return                         BOOLEAN for success. 
    *
    * @author                         RicardoNunoAlmeida
    * @version                        2.5.0.7.7   
    * @since                          2010/02/07
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_diag  OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_diagnosis
    (
        i_lang IN language.id_language%TYPE,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the episode description in which the diagnosis was registered
    *
    * @param i_lang           language id
    * @param i_prof           professional id (type: professional id, institution id and software id)
    * @param i_episode        episode ID
    * @param i_epis_origin    episode ID where the diagnosis was registered
    * 
    * @return                 formatted text containing the episode description
    * 
    * @author                 Jos?Silva
    * @version                2.6.0.1  
    * @since                  2010/03/29
    **********************************************************************************************/
    FUNCTION get_origin_diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_epis_origin IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the options available in the diagnosis filter
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_options                Filter options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jos?Silva
    * @version                        1.0   
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION get_diag_filter_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**************************************************************************
    * get profissional with diagnosis state logic
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_epis_diagnosis      Epis_diagnosis ID
    * 
    * Return diagnosis date 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/14                              
    **************************************************************************/
    FUNCTION get_epis_diagnosis_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis.id_professional_diag%TYPE;

    /**************************************************************************
    * get diagnosis date with state logic
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_epis_diagnosis      Epis_diagnosis ID
    * 
    * Return diagnosis date 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/14                              
    **************************************************************************/
    FUNCTION get_epis_diagnosis_date
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis.dt_epis_diagnosis_tstz%TYPE;
    /********************************************************************************************
    * Get episode diagnosis
    *
    * @param i_lang                          Preferred language ID for this professional
    * @param i_prof                          Object (professional ID, institution ID, software ID)
    * @param i_epis                          episode identifier
    * @param i_diag                          diagnosis identifier
    * @param i_desc_diag                     diagnosis description
    * @param o_epis_diag                     epis diagnosis identfier
    * @param o_flg_add_problem               flg_add_problem
    
    *
    * @return                         true or false
    *
    * @author                          Paulo teixeira
    * @version                         0.1
    * @since                           2011/08/30
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_diag            IN diagnosis.id_diagnosis%TYPE,
        i_desc_diag       IN sys_message.desc_message%TYPE,
        o_epis_diag       OUT epis_diagnosis.id_epis_diagnosis%TYPE,
        o_flg_add_problem OUT epis_diagnosis.flg_add_problem%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get episode diagnosis
    *
    * @param i_lang                          Preferred language ID for this professional
    * @param i_prof                          Object (professional ID, institution ID, software ID)    
    * @param i_id_diagnosis                  Diagnosis identifier
    * @param o_flg_other                     Diagnosis flg other
    * @param o_error                         Error info
    
    *
    * @return                         true or false
    *
    * @author                          Sofia Mendes
    * @version                         2.6.2
    * @since                           16-Dec-2011
    **********************************************************************************************/
    FUNCTION get_diag_flg_other
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_diagnosis IN diagnosis.id_diagnosis%TYPE,
        o_flg_other    OUT diagnosis.flg_other%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get diagnosis code domain (and synonims)
    * 
    * @return                          Code domain for diagnosis and synonims
    *
    * @author                          Miguel Moreira
    * @version                         2.6.1.6
    * @since                           27-Feb-2012
    **********************************************************************************************/
    FUNCTION get_diagnosis_domain RETURN table_varchar;

    /**
    * Get diagnosis path based on its hierarchy
    *
    * @param   i_diagnosis          Diagnosis identifier
    *
    * @return  The diagnosis path
    *
    * @author  Sérgio Santos
    * @version v2.5.2
    * @since   08/03/2012
    */
    FUNCTION get_diagnosis_path(i_diagnosis IN diagnosis.id_diagnosis%TYPE) RETURN VARCHAR2;

    /**
    * Get diagnosis path based on its hierarchy
    *
    * @param   i_lang          Language ID
    * @param   i_prof          Professional data
    * @param   i_diagnosis     Diagnosis ID
    * @param   o_path          Diagnosis path cursor
    * @param   o_error         Error information
    *
    * @return  TRUE/FALSE
    *
    * @author  Sergio Dias
    * @version v2.6.3.9.1
    * @since   Jan-10-2014
    */
    FUNCTION get_diagnosis_path
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE,
        o_path      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_list                   Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos?Silva
    * @version                        1.0
    * @since                          2012/02/29
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN epis_diagnosis.flg_type%TYPE,
        o_list     OUT pk_edis_types.diagnosis_cur,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the parent diagnosis (to be used in the views that simultate the old column DIAGNOSIS.ID_DIAGNOSIS_PARENT)
    *
    * @param i_diagnosis              diagnosis ID (corresponding to ID_CONCEPT_VERSION in the new model)
    * @param i_institution            institution ID
    * @param i_software               software ID
    *
    * @return                         diagnosis parent ID
    *
    * @author                         Jos?Silva
    * @version                        1.0
    * @since                          2012/03/07
    **********************************************************************************************/
    FUNCTION get_diagnosis_parent
    (
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN diagnosis.id_diagnosis%TYPE;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: FLASH)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_params                XML with all output parameters
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 1.0
    * @since   24-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT CLOB,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_params                XML with all output parameters
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 1.0
    * @since   24-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT pk_edis_types.table_out_epis_diags,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_epis_diagnoses        Epis diagnoses record
    * @param   o_params                Output parameters record
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   24-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diagnoses IN pk_edis_types.rec_in_epis_diagnoses,
        o_params         OUT pk_edis_types.table_out_epis_diags,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_patient               patient ID
    * @param   i_episode               episode ID
    * @param   i_diagnosis             Table with diagnosis ID
    * @param   i_alert_diagnosis       Table with alert diagnosis ID
    * @param   i_desc_diag             Table with diagnosis descriptions
    * @param   i_task_type             task type ID
    * @param   i_cdr_call              cdr call ID
    * @param   o_params                Output parameters record
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   22-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN table_number,
        i_alert_diagnosis IN table_number DEFAULT NULL,
        i_desc_diag       IN table_varchar DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_params          OUT pk_edis_types.table_out_epis_diags,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_patient               patient ID
    * @param   i_episode               episode ID
    * @param   i_diagnosis             diagnosis ID
    * @param   i_alert_diagnosis       alert diagnosis ID
    * @param   i_desc_diag             diagnosis descriptions
    * @param   i_task_type             task type ID
    * @param   i_cdr_call              cdr call ID
    * @param   o_params                Output parameters record
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   22-03-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_desc_diag       IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_params          OUT pk_edis_types.table_out_epis_diags,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_params                 XML with all input parameters
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB
    ) RETURN pk_edis_types.rec_in_epis_diagnosis;
    --
    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_params                 Table of XML with all input parameters
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN table_clob
    ) RETURN pk_edis_types.table_in_epis_diagnosis;
    --
    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              Table with diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN table_table_number,
        i_alert_diagnosis IN table_table_number DEFAULT NULL,
        i_desc_diag       IN table_table_varchar DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.table_in_epis_diagnosis;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              Table with diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN table_number,
        i_alert_diagnosis IN table_number DEFAULT NULL,
        i_desc_diag       IN table_varchar DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.rec_in_epis_diagnosis;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    * @param i_id_epis_diagnosis      epis_diagnosis ID
    * @param i_flg_status             Diagnosis status
    * @param i_spec_notes             Diagnosis notes
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_diagnosis         IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis   IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_desc_diag         IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_task_type         IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call          IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_status        IN epis_diagnosis.flg_status%TYPE DEFAULT NULL,
        i_spec_notes        IN epis_diagnosis.notes%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.rec_in_epis_diagnosis;
    --
    /**********************************************************************************************
    * Sets the diagnosis notes  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param i_epis_diag_notes        previous diagnosis notes ID (if it is an edition)
    * @param i_notes                  registered notes
    * @param o_epis_diag_notes        diagnosis notes ID that was saved
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jos?Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION set_epis_diag_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diag_notes IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        i_notes           IN epis_diagnosis_notes.notes%TYPE,
        o_epis_diag_notes OUT epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Function that gives all the information registered in a diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    *
    * @return                         diagnosis general info
    *
    * @author                         Jos?Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE
    ) RETURN pk_edis_types.rec_epis_diagnosis;
    --
    /********************************************************************************************
    * Get diagnosis description (only used by the order sets tool)
    *
    * @param    i_lang             preferred language ID
    * @param    i_prof             object (id of professional, id of institution, id of software)
    * @param    i_episode          episode ID
    * @param    i_rec_diagnosis    diagnosis record
    *
    * @return   varchar2           diagnosis description
    *
    * @author   Tiago Silva
    * @since    2012/10/16
    ********************************************************************************************/
    FUNCTION get_diag_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_rec_diagnosis IN pk_edis_types.rec_in_diagnosis
    ) RETURN pk_translation.t_desc_translation;
    --
    /********************************************************************************************
    * Get diagnosis description (only used by the order sets tool)
    *
    * @param    i_lang                 preferred language ID
    * @param    i_prof                 object (id of professional, id of institution, id of software)
    * @param    i_episode              episode ID
    * @param    i_id_diagnosis         diagnosis ID
    * @param    i_id_alert_diagnosis   alert diagnosis ID    
    *
    * @return   varchar2           diagnosis description
    *
    * @author   Tiago Silva
    * @since    2012/10/16
    ********************************************************************************************/
    FUNCTION get_diag_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_id_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN pk_translation.t_desc_translation;
    --
    /**********************************************************************************************
    * List all cancer diagnosis registered in a patient
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_patient             Patient id
    * @param o_cursor                 Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos?Silva
    * @version                        2.6.2.1
    * @since                          2012/Mar/29
    **********************************************************************************************/
    FUNCTION get_cancer_diagnosis_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get all the cancer diagnoses registered previously in a patient
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_patient                Patient id
    * @param o_diags                  Diagnoses description list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos?Silva
    * @version                        2.6.2.1
    * @since                          2012/Apr/12
    **********************************************************************************************/
    FUNCTION get_pat_prev_cancer_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_diags   OUT table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * get actions of the diagnosis general notes
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_task_request           task request id (monitorization id)
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                26-Mar-2012
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * get actions of the final diagnosis 
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_task_request           task request id (epis_diagnosis)
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.3
    * @since                                29-Nov-2012
    **********************************************************************************************/
    FUNCTION get_actions_final_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Get diagnosis medical assossiated synonyms
    *
    * @param   i_lang               Language identifier
    * @param   i_diagnosis          Diagnosis identifier
    *
    * @return  BOOLEAN for success. 
    *
    * @author  Sérgio Santos
    * @version v2.5.2
    * @since   08/03/2012
    */
    FUNCTION get_diagnosis_synonyms
    (
        i_lang      IN language.id_language%TYPE,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE,
        o_diag_syn  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Return record diagnosis
    *
    * @param       i_rec_epis_diag          Epis diagnosis record
    *
    * @return      t_table_diagnosis        Diagnosis table
    *
    * @author                               Alexandre Santos
    * @version                              2.6.2.1
    * @since                                03-04-2012
    **********************************************************************************************/
    FUNCTION tf_diagnosis(i_rec_epis_diag IN pk_edis_types.rec_in_epis_diagnosis) RETURN t_table_diagnoses;

    /**************************************************************************
    * Get the diagnosis creation date
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_epis_diagnosis      Epis diagnosis ID
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          19-Sep-2012                            
    **************************************************************************/
    FUNCTION get_diag_hist_creation_dt
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis_hist.dt_creation_tstz%TYPE;
    --
    /**********************************************************************************************
    * Listar os diagnósticos definitivos do episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_id_episode             episode id
    *
    * @param o_error                  Error message
    *
    * @return                         Final Diagnosis
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.8.1
    * @since                          20-Sept-2013
    **********************************************************************************************/
    FUNCTION get_final_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Get the diagnosis cause (ALERT-261232)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              diagnosis id
    * @param o_desc_cause             Cause description
    * @param o_code_cause             Cause code
    * @param o_error                  Error message
    *
    * @return                         BOOLEAN for success. 
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3.8.2
    * @since                          08-10-2013
    **********************************************************************************************/
    FUNCTION get_diagnosis_cause
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_diagnosis  IN diagnosis.id_diagnosis%TYPE,
        o_desc_cause OUT pk_translation.t_desc_translation,
        o_code_cause OUT diagnosis.code_icd%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Get the diagnosis cause description (ALERT-261232)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              diagnosis id
    *
    * @return                         Cause description. 
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3.8.2
    * @since                          08-10-2013
    **********************************************************************************************/
    FUNCTION get_diag_cause_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Get the diagnosis cause code (ALERT-261232)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              diagnosis id
    *
    * @return                         Cause code. 
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3.8.2
    * @since                          08-10-2013
    **********************************************************************************************/
    FUNCTION get_diag_cause_code
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2;
    --
    /**************************************************************************
    * Get the diagnosis creation date
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_mcdt_req_diagnosis     MCDT REQ DIAGNOSIS ID
    *                                                                         
    * @author                         Alexandre Santos                 
    * @version                        2.6.4                            
    * @since                          29-Sep-2014
    **************************************************************************/
    FUNCTION get_mcdt_description
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_mcdt_req_diagnosis     IN mcdt_req_diagnosis.id_mcdt_req_diagnosis%TYPE,
        i_flg_terminology_server IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
     * Get all diagnosis with std_diag_desc and the notes that were documented in given episode list
     *
     * @param i_lang                   The user language id
     * @param i_prof                   The Professional, software and institution executing the request
     * @param i_tbl_episode            Episodes array
     * @param o_diag                   A cursor with the DESC_INFO as 'diag description, notes'
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         Nuno Alves
     * @version                        2.6.3.8.2
     * @since                          2015/05/06
     *
     * Notes: For use on previous visits and current encounter
     *        Diagnosis description (code) (Principal diagnosis (only if Yes), status, date of initial diagnosis), Specific notes 
     *        Sorted by:  Type of diagnosis (principal listed first) and then status (confirmed, under investigation, ruled out)
    **********************************************************************************************/
    FUNCTION get_epis_diag_with_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tbl_episode IN table_number,
        o_diag        OUT pk_types.cursor_type,
        o_impressions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get congenital anomalies (1st, 2nd or all) for NOM024
     *
     * @param i_lang                  The user language id
     * @param i_prof                  The Professional, software and institution executing the request
     * @param i_id_episode            Episode ID
     * @param i_nr_anomalie           Anomalie number (first or second)
     *
     * @return                        Anomalie description
     * 
     * @author                        Vanessa Basottelli
     * @version                       2.7.0
     * @since                         06/02/2017
     *
    **********************************************************************************************/
    FUNCTION get_congenital_anomalies
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_nr_anomalie IN NUMBER
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Get DIFF DIAGNOSIS viewer checklist 
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
    FUNCTION get_diag_diff_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get FINAL DIAGNOSIS viewer checklist 
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
    FUNCTION get_diag_final_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    --

    /********************************************************************************************
    * Get DIAGNOSIS viewer checklist 
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
    * @author                         Carlos Ferreira
    * @version                        2.6.5
    * @since                          2017-02-23
    **********************************************************************************************/
    FUNCTION get_diagnoses_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get social DIAGNOSIS viewer checklist 
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
    FUNCTION get_diag_social_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get DIAGNOSIS viewer checklist 
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
    FUNCTION get_diagnosis_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    * Get DIAGNOSIS viewer checklist depending of type of episode and status
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
    * @author                         Carlos Ferreira
    * @version                        2.6.5
    * @since                          2017-02-27
    **********************************************************************************************/
    FUNCTION get_vwr_diag_type_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_epis_type  IN NUMBER,
        i_tbl_status IN table_varchar
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Listar os diagnósticos definitivos do episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_preg_out_type          type Abortion (A) or Delivery(D)
    * @param o_exists                 IF exists, return 'Y', otherwise, return 'N'
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Pedro Henriques
    * @version                        1.0 
    * @since                          2017/07/27
    **********************************************************************************************/
    FUNCTION get_final_diag_abort_deliv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_preg_out_type IN pat_pregnancy.flg_preg_out_type%TYPE,
        i_diagnosis     IN table_number,
        o_exists        OUT VARCHAR2,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**######################################################
      GLOBAIS
    ######################################################**/
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    --
    g_inst_type_cs    CONSTANT institution.flg_type%TYPE := 'C';
    g_inst_type_hs    CONSTANT institution.flg_type%TYPE := 'H';
    g_diag_type_icd   CONSTANT diagnosis.flg_type%TYPE := 'D'; --ICD9
    g_diag_type_icpc  CONSTANT diagnosis.flg_type%TYPE := 'P'; --ICPC2
    g_diag_type_icdcm CONSTANT diagnosis.flg_type%TYPE := 'C'; --ICD9CM
    g_diag_freq       CONSTANT diagnosis_dep_clin_serv.flg_type%TYPE := 'M';
    g_diag_pesq       CONSTANT diagnosis_dep_clin_serv.flg_type%TYPE := 'P';
    g_diag_pregn      CONSTANT diagnosis_dep_clin_serv.flg_type%TYPE := 'G'; -- pregnancy button
    --
    g_diag_available CONSTANT diagnosis.flg_available%TYPE := 'Y';
    g_diag_select    CONSTANT diagnosis.flg_select%TYPE := 'Y';
    --
    g_complaint_act          CONSTANT epis_complaint.flg_status%TYPE := 'A';
    g_available              CONSTANT doc_template_diagnosis.flg_available%TYPE := 'Y';
    g_epis_active            CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_temp              CONSTANT episode.flg_status%TYPE := 'T';
    g_epis_status_c          CONSTANT epis_diagnosis.flg_status%TYPE := 'C';
    g_epis_diag_status       CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_STATUS';
    g_epis_diag_status_p     CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_STATUS_P';
    g_epis_diag_status_d     CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_STATUS_D';
    g_epis_diag_type_d       CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_TYPE_D';
    g_epis_diag_notes_status CONSTANT sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS_NOTES.FLG_STATUS';
    --
    g_diag_type_p CONSTANT VARCHAR2(1) := 'P';
    g_diag_type_d CONSTANT VARCHAR2(1) := 'D';
    g_diag_type_b CONSTANT VARCHAR2(1) := 'B';
    g_diag_type_x CONSTANT VARCHAR2(1) := 'X';
    --
    g_flg_final_type_p CONSTANT epis_diagnosis.flg_final_type%TYPE := 'P';
    g_flg_final_type_s CONSTANT epis_diagnosis.flg_final_type%TYPE := 'S';
    --
    g_flg_type_ddif  CONSTANT VARCHAR2(2) := 'DD';
    g_flg_type_disch CONSTANT VARCHAR2(2) := 'D';
    --
    g_id_soft_inpatient CONSTANT NUMBER := pk_alert_constant.g_soft_inpatient;
    g_id_soft_oris      CONSTANT NUMBER := pk_alert_constant.g_soft_oris;
    --
    g_aproved_clin      CONSTANT pat_problem.flg_status%TYPE := 'M';
    g_pat_prob_active   CONSTANT pat_problem.flg_status%TYPE := 'A';
    g_pat_prob_canceled CONSTANT pat_problem.flg_status%TYPE := 'C';
    g_pat_prob_excluded CONSTANT pat_problem.flg_status%TYPE := 'E';

    g_selected CONSTANT VARCHAR2(1) := 'S';
    --
    g_yes CONSTANT VARCHAR2(1) := pk_alert_constant.g_yes;
    g_no  CONSTANT VARCHAR2(1) := pk_alert_constant.g_no;

    g_diagnosis_type sys_config.value%TYPE;
    g_diag_show_code sys_config.value%TYPE;
    g_doctor     CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_doc;
    g_social_cat CONSTANT category.flg_type%TYPE := 'S';
    g_nutri_cat  CONSTANT category.flg_type%TYPE := 'U';
    g_flg_active VARCHAR2(1);
    g_mcdt_cancel CONSTANT VARCHAR2(1) := 'C';
    --
    g_dgn_session CONSTANT notes_config.notes_code%TYPE := 'DGN';
    --
    g_semi_comma VARCHAR2(1) := ';';
    g_hifen      VARCHAR2(2) := '- ';
    --
    g_code_format_start CONSTANT sys_config.value%TYPE := 'S';
    g_code_format_end   CONSTANT sys_config.value%TYPE := 'E';
    --
    g_sys_config_show_term_diagnos CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSES_SHOW_TERMINOLOGY_DIAGNOSIS';
    g_sys_config_show_term_problem CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSES_SHOW_TERMINOLOGY_PROBLEMS';
    g_sys_config_show_term_surg    CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSES_SHOW_TERMINOLOGY_SURGICAL_HISTORY';
    g_sys_config_show_term_medical CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSES_SHOW_TERMINOLOGY_MEDICAL_HISTORY';
    g_sys_config_show_term_cong    CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSES_SHOW_TERMINOLOGY_CONGENITAL_ANOMALIES';
    g_sys_cfg_show_all_diag_states CONSTANT sys_config.id_sys_config%TYPE := 'FINAL_DIAGNOSIS_SHOW_ALL_STATES';
    --
    e_call_exception           EXCEPTION;
    e_final_type_exception     EXCEPTION;
    e_primary_diag_exception   EXCEPTION;
    e_diagnosis_already_exists EXCEPTION;

    g_warning_popup_ok CONSTANT VARCHAR2(3 CHAR) := 'YW';

END pk_diagnosis;
/
