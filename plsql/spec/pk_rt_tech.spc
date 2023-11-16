/*-- Last Change Revision: $Rev: 2028938 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_rt_tech IS
    --
    /**********************************************************************************************
    * Grelha do técnico respiratório, para visualizar todos os pacientes com requisições de MCTS a que ele tem acesso
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          category professional
    * @param o_grid                   cursor with all episodes 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/18
    **********************************************************************************************/
    FUNCTION get_grid_my_pat_rt
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Grelha do técnico respiratório, para visualizar todos os pacientes alocados ás suas salas
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          category professional
    * @param o_grid                   cursor with all episodes 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/22
    **********************************************************************************************/
    FUNCTION get_grid_all_pat_rt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Retorna apenas as tarefas, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_prof_cat_type          category professional
    * @param i_type_context           tipo de contexto:I -Intervention; E - Exam; D - Drug; A - Analysis; M - Monitorization 
    *
    * @return                         Retorna a informação neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    **********************************************************************************************/
    FUNCTION get_context_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_type_context  IN VARCHAR2
    ) RETURN VARCHAR2;
    -- 
    /**********************************************************************************************
    * Retorna apenas o exame, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_exam                   Retorna o exame neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    **********************************************************************************************/
    FUNCTION get_epis_exam_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_exam    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Retorna apenas a analise, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_visit                  visit id
    * @param o_analysis               Retorna a análise neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    **********************************************************************************************/
    FUNCTION get_epis_analysis_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     profissional,
        i_visit    IN visit.id_visit%TYPE,
        o_analysis OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Retorna apenas o procedimento, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_interv                 Retorna o procedimento neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    **********************************************************************************************/
    FUNCTION get_epis_interv_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_interv  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Retorna apenas o medicamento, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_drug                   Retorna o medicamento neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    **********************************************************************************************/
    FUNCTION get_epis_drug_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_drug    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Retorna apenas a monitorização, em atraso, que um dado perfil pode efectuar
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_monit                  Retorna o monitorização neste formato: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    **********************************************************************************************/
    FUNCTION get_epis_monit_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    profissional,
        i_episode IN episode.id_episode%TYPE,
        o_monit   OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Verificar se existem análises que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_analysis_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_visit       IN visit.id_visit%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Verificar se existem exames que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_exam_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Verificar se existem procedimentos que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_interv_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Verificar se existem medicamentos que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_drug_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Verificar se existem monitorizações que um dado perfil pode efectuar
    *
    * @param i_prof                   professional id
    * @param i_institution            institution id
    * @param i_software               software id
    * @param i_episode                episode id
    *
    * @return                         number
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_monit_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    FUNCTION get_epis_treatment_count
    (
        i_prof        IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_visit       IN visit.id_visit%TYPE,
        i_episode     IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    --
    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para o técnico respiratório
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category   
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/24
    **********************************************************************************************/
    FUNCTION get_epis_active_rttech
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
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

    /**********************************************************************************************
    * Grelha do técnico respiratório, para visualizar todos os pacientes com requisições de MCTS a que ele tem acesso
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          category professional
    * @param o_grid                   cursor with all episodes 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Elisabete Bugalho
    * @date    15-01-2014
    * @version 2.6.3
    **********************************************************************************************/
    FUNCTION get_grid_tasks_rt
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params_grid_tasks
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );
    --
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_error        VARCHAR2(4000);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_date_mask    VARCHAR2(16) := 'YYYYMMDDHH24MISS';
    --
    g_exception EXCEPTION;
    g_found           BOOLEAN;
    g_current_profile profile_template.id_profile_template%TYPE;
    --
    g_active   CONSTANT VARCHAR2(2) := 'A';
    g_canceled CONSTANT VARCHAR2(2) := 'C';
    --
    g_yes      CONSTANT VARCHAR2(1) := 'Y';
    g_no       CONSTANT VARCHAR2(1) := 'N';
    g_rank_inf CONSTANT NUMBER(12) := 900;
    g_rank_sup CONSTANT NUMBER(12) := 999;
    --
    g_software_outp CONSTANT software.id_software%TYPE := 1;
    g_software_oris CONSTANT software.id_software%TYPE := 2;
    g_software_care CONSTANT software.id_software%TYPE := 3;
    g_software_edis CONSTANT software.id_software%TYPE := 8;
    g_software_inp  CONSTANT software.id_software%TYPE := 11;
    g_software_pp   CONSTANT software.id_software%TYPE := 12;
    --
    g_no_triage_color_id CONSTANT triage_color.id_triage_color%TYPE := 9;
    g_no_color_rank      CONSTANT triage_color.rank%TYPE := 999;
    --
    g_intervention   CONSTANT VARCHAR2(2) := 'I';
    g_exam           CONSTANT VARCHAR2(2) := 'E';
    g_analysis       CONSTANT VARCHAR2(2) := 'A';
    g_drug           CONSTANT VARCHAR2(2) := 'D';
    g_monitorization CONSTANT VARCHAR2(2) := 'M';
    --
    g_flg_time_epis CONSTANT exam_req.flg_time%TYPE := 'E';
    g_flg_time_next CONSTANT exam_req.flg_time%TYPE := 'N';
    g_flg_time_betw CONSTANT exam_req.flg_time%TYPE := 'B';
    --
    g_exam_type_img CONSTANT exam.flg_type%TYPE := 'I';
    --
    g_exam_pending CONSTANT exam_req.flg_status%TYPE := 'D';
    g_exam_req     CONSTANT exam_req.flg_status%TYPE := 'R';
    --
    g_analysis_pending CONSTANT analysis_req.flg_status%TYPE := 'D';
    g_analysis_req     CONSTANT analysis_req.flg_status%TYPE := 'R';
    --
    g_interv_pending  CONSTANT interv_prescription.flg_status%TYPE := 'D';
    g_interv_req      CONSTANT interv_prescription.flg_status%TYPE := 'R';
    g_interv_ong      CONSTANT interv_prescription.flg_status%TYPE := 'P';
    g_interv_type_sos CONSTANT interv_presc_det.flg_interv_type%TYPE := 'S';
    g_interv_type_con CONSTANT interv_presc_det.flg_interv_type%TYPE := 'C';
    --
    g_monit_pending CONSTANT monitorization_vs.flg_status%TYPE := 'D';
    g_monit_active  CONSTANT monitorization_vs.flg_status%TYPE := 'A';

    g_task_analysis        CONSTANT VARCHAR2(1) := 'A';
    g_task_exam            CONSTANT VARCHAR2(1) := 'E';
    g_no_triage_color      CONSTANT triage_color.color%TYPE := '0x787864';
    g_no_triage_color_text CONSTANT triage_color.color_text%TYPE := '0xFFFFFF';

    g_package_name  VARCHAR2(200);
    g_package_owner VARCHAR2(200);

    g_icon_ft          CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer CONSTANT VARCHAR2(1) := 'T';
    g_desc_grid        CONSTANT VARCHAR2(1) := 'G';
    g_ft_color         CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_ft_triage_white  CONSTANT VARCHAR2(200) := '0x787864';
    g_ft_status        CONSTANT VARCHAR2(1) := 'A';

END pk_rt_tech;
/
