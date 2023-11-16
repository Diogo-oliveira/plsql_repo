/*-- Last Change Revision: $Rev: 2028978 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_clinical_info AS

    FUNCTION get_ci_summary_labels
    (
        i_lang      IN language.id_language%TYPE,
        i_mess_code IN table_varchar,
        i_prof      IN profissional,
        o_mess      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ci_vs_reads
    (
        i_lang        IN language.id_language%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_vital_signs OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ci_grid
    (
        i_lang             IN language.id_language%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        o_anest            OUT pk_types.cursor_type,
        o_hemo             OUT pk_types.cursor_type,
        o_proc             OUT pk_types.cursor_type,
        o_prot             OUT pk_types.cursor_type,
        o_days_warning     OUT sys_message.desc_message%TYPE,
        o_flg_show_warning OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_string_task(i_lang IN language.id_language%TYPE,
                             -- JS, 2007-09-08 - Timezone
                             i_prof        IN profissional,
                             i_type        IN VARCHAR2,
                             i_epis_status IN episode.flg_status%TYPE,
                             i_flg_time    IN VARCHAR2,
                             i_flg_status  IN VARCHAR2,
                             i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_icon_name   IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION create_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_icon_name   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION get_ci_vs_grid
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_vs_header  OUT pk_types.cursor_type,
        o_vs_det     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sr_string_task(i_lang IN language.id_language%TYPE,
                                -- JS, 2007-09-08 - Timezone
                                i_prof        IN profissional,
                                i_type        IN VARCHAR2,
                                i_epis_status IN episode.flg_status%TYPE,
                                i_flg_time    IN VARCHAR2,
                                i_flg_status  IN VARCHAR2,
                                i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
                                i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
                                i_icon_name   IN VARCHAR2,
                                o_error       OUT t_error_out) RETURN VARCHAR2;
    /********************************************************************************************
    * retrieve all available diagnosis, by episode
    *
    * @param i_lang        Id Language in use by the user
    * @param i_prof        Professional ID, Institution ID, Software ID
    * @param i_episode     Episode ID
    *
    * @return              string containing all available diagnosis for a certain episode
    *
    * @author              Pedro Santos
    * @since               2008/08/21
       ********************************************************************************************/
    FUNCTION get_summary_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_short_description IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    FUNCTION get_summary_diagnosis
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter o diagnóstico base da página resumo
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                    I_EPISODE - ID do episódio
                                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_TITLE - Título a mostrar na página resumo  
                                    O_DIAG -  Lista de Diagnósticos base do episódio
                                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/30
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_summary_intervention
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_interv  OUT pk_types.cursor_type,
        o_labels  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter a Cirurgia proposta da página resumo
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                    I_EPISODE - ID do episódio
                                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_TITLE - Título a mostrar na página resumo  
                                    O_DIAG -  Lista de Diagnósticos base do episódio
                                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/30
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_summary_receive_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_receive OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter informação sobre o acolhimento para a página resumo
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                    I_EPISODE - ID do episódio
                                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_TITLE - Título a mostrar na página resumo  
                                    O_DIAG -  Lista de Diagnósticos base do episódio
                                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/30
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_summary_prior_surg_epis
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter informação sobre antecedentes cirúrgicos do doente para a página resumo
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                    I_EPISODE - ID do episódio
                                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_TITLE - Título a mostrar na página resumo  
                                    O_DIAG -  Lista de Diagnósticos base do episódio
                                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/30
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_summary_prior_prob_epis
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter informação sobre outros antecedentes relevantes do doente para a página resumo
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                    I_EPISODE - ID do episódio
                                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_TITLE - Título a mostrar na página resumo  
                                    O_DIAG -  Lista de Diagnósticos base do episódio
                                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/30
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_summary_medication
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter informação sobre medicação pessoal do doente para a página resumo
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                    I_EPISODE - ID do episódio
                                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_TITLE - Título a mostrar na página resumo  
                                    O_DIAG -  Lista de Diagnósticos base do episódio
                                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/30
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_surgical_procedures
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_show_code IN VARCHAR2 DEFAULT 'N',
        o_surg_proc     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_surgical_procedure_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_proposed_surgery
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_flg_show_code IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;
    /******************************************************************************
       OBJECTIVO:   Obter as cirurgias propostas concatenadas numa única string
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                                    I_EPISODE - ID do episódio
                                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_TITLE - Título a mostrar na página resumo  
                                    O_DIAG -  Lista de Diagnósticos base do episódio
                                          O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/08/30
      NOTAS: 
    *********************************************************************************/

    /*
    * Obter os id_content das cirurgias propostas concatenadas numa única string.
    * INline function. Used by the waiting list search function in pk_wtl_pbl_core
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_episode          surgery episode from which to extract surg. procedures
    * 
    * return true /false
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    18-06-2010
    */
    FUNCTION get_surgeries_id_content
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_sys_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_intern_name IN sys_shortcut.intern_name%TYPE
    ) RETURN NUMBER;
    /******************************************************************************
       OBJECTIVO:   Obtem ID do atalho de um ecrã 
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_INTERN_NAME - Nome do atalho
                           SAIDA:   
      
      CRIAÇÃO: RB 2006/02/23
      NOTAS:  
    *********************************************************************************/

    FUNCTION get_surg_proc_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_code_int   IN intervention.code_intervention%TYPE,
        i_code       IN interv_codification.standard_code%TYPE,
        i_laterality IN sr_epis_interv.laterality%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Constroi a descrição dos procedimentos cirúrgicos com o seguinte formato:
    * descrição procedimentos cirurgicos (codigo icd) - lateralidade
    *
    * @param i_lang                   Id do idioma
    * @param i_code_int               Código de intervenção
    * @param i_code                   Código do ICD
    * @param i_laterality             lateralidade associado ao procedimento cirúrgico
    * 
    * @return                         Descrição que vai ser mostrada
    * 
    * @author                         Filipe Silva
    * @version                        2.5   
    * @since                          2009/07/16
    **********************************************************************************************/

    /********************************************************************************************
    * Returns the value of specific elements from last documentation for an area, episode and template
    * The element's internal name is the internal name of documentation table
    *
    * @param i_lang                Language ID                                                                                              
    * @param i_prof                Professional, software and institution ids                                                                                                                                          
    * @param i_episode             Episode ID 
    * @param i_flg_val_group       String to filter de group of internal names
    * @param o_element_values      Element values
    * @param o_error               Error info
    *                        
    * @return                      true or false on success or error
    *
    * @autor                       Filipe Silva
    * @version                     2.5.7.0.8
    * @since                       2010/03/23
    **********************************************************************************************/
    FUNCTION get_last_element_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_val_group  IN sr_surgery_validation.flg_group%TYPE,
        o_element_values OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * return coded surgical procedure description       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_sr_intervention     Intervention ID                       
    *
    * @return                         Surgical procedure description                                                           
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/04/27                              
    **************************************************************************/
    FUNCTION get_coded_surg_procedure_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * return principal surgical procedure for a episode      
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_episode                EPISODE ID                       
    *
    * @return                         Principal Surgical procedure                                                            
    *
    * @author                         Elisabete Bugalho                            
    * @version                        2.6.2                                 
    * @since                          2012/04/05                              
    **************************************************************************/
    FUNCTION get_primary_surg_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    --Declaração de variáveis e constantes
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;
    g_status_y      CONSTANT VARCHAR2(1) := 'Y';
    g_status_active CONSTANT VARCHAR2(1) := 'A';
    g_cancel        CONSTANT VARCHAR2(1) := 'C';
    g_available     CONSTANT VARCHAR2(1) := 'Y';
    g_excluded      CONSTANT VARCHAR2(1) := 'R';

    g_icon        CONSTANT VARCHAR2(1) := 'I';
    g_no_color    CONSTANT VARCHAR2(1) := 'X';
    g_color_red   CONSTANT VARCHAR2(1) := 'R';
    g_color_green CONSTANT VARCHAR2(1) := 'G';

    g_flg_status_f CONSTANT VARCHAR2(1) := 'F';
    g_flg_status_i CONSTANT VARCHAR2(1) := 'I';
    g_flg_status_c CONSTANT VARCHAR2(1) := 'C';
    g_flg_status_r CONSTANT VARCHAR2(1) := 'R';
    g_flg_status_l CONSTANT VARCHAR2(1) := 'L';
    g_flg_status_p CONSTANT VARCHAR2(1) := 'P';
    g_flg_status_b CONSTANT VARCHAR2(1) := 'B';
    g_flg_status_e CONSTANT VARCHAR2(1) := 'E';
    g_flg_status_t CONSTANT VARCHAR2(1) := 'T';
    g_flg_status_a CONSTANT VARCHAR2(1) := 'A';
    g_flg_status_d CONSTANT VARCHAR2(1) := 'D';
    g_flg_status_s CONSTANT VARCHAR2(1) := 'S';

    g_harv_stat_h CONSTANT VARCHAR2(1) := 'H';
    g_harv_stat_t CONSTANT VARCHAR2(1) := 'T';
    g_harv_stat_f CONSTANT VARCHAR2(1) := 'F';

    g_drug_type_fliuds CONSTANT drug.flg_type%TYPE := 'F';

    g_interv_type_s CONSTANT VARCHAR2(1) := 'S';
    g_interv_type_a CONSTANT VARCHAR2(1) := 'A';
    g_take_type_s   CONSTANT VARCHAR2(1) := 'S';
    g_take_type_c   CONSTANT VARCHAR2(1) := 'C';

    g_surg_prot CONSTANT VARCHAR2(1) := 'S';
    g_anes_prot CONSTANT VARCHAR2(1) := 'A';

    g_vs_rel_sum  CONSTANT VARCHAR2(1) := 'S';
    g_vs_rel_conc CONSTANT VARCHAR2(1) := 'C';

    g_epis_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_inactive CONSTANT episode.flg_status%TYPE := 'I';

    g_flg_time_e CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_flg_time_n CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_time_b CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_flg_time_r CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_flg_time_g CONSTANT VARCHAR2(1 CHAR) := 'G';

    g_text CONSTANT VARCHAR2(1) := 'T';
    g_date CONSTANT VARCHAR2(1) := 'D';
    g_read CONSTANT VARCHAR2(1) := 'L';

    g_anamnesis CONSTANT VARCHAR2(1) := 'A';

    g_summary_filter     CONSTANT sys_message.code_message%TYPE := 'SUMMARY_CLOSED_TASK_FILTER_DESC';
    g_summary_filter_one CONSTANT sys_message.code_message%TYPE := 'SUMMARY_CLOSED_TASK_FILTER_DESC_ONE';

    --prescrição
    g_local_prescription CONSTANT drug_req.flg_status%TYPE := 'A';
    g_debug_on           CONSTANT VARCHAR2(3) := 'YES';
    g_soro               CONSTANT VARCHAR2(4) := 'SORO';
    g_drug               CONSTANT VARCHAR2(1) := 'M';
    g_local              CONSTANT VARCHAR2(5) := 'LOCAL';

    g_material_kit CONSTANT sr_equip.id_sr_equip%TYPE := 72;

    g_value_document_type CONSTANT PLS_INTEGER := 1;

    g_receive_doc_area CONSTANT doc_area.id_doc_area%TYPE := 7;

    g_flg_type_i CONSTANT VARCHAR2(1) := 'I';
    g_flg_type_a CONSTANT VARCHAR2(1) := 'A';
    g_flg_type_p CONSTANT VARCHAR2(1) := 'P';
    g_flg_type_o CONSTANT VARCHAR2(1) := 'O'; --Outros que não análises

    g_analysis_type_req     VARCHAR2(2) := 'AR';
    g_analysis_type_req_det VARCHAR2(2) := 'AD';
    g_analysis_type_harv    VARCHAR2(2) := 'AH';

    g_exam_type_req ti_log.flg_type%TYPE := 'ER';
    g_exam_type_det ti_log.flg_type%TYPE := 'ED';

    g_ti_interv        ti_log.flg_type%TYPE := 'PR';
    g_epis_diag_status sys_domain.code_domain%TYPE := 'EPIS_DIAGNOSIS.FLG_STATUS';
    g_flg_code_type_c CONSTANT VARCHAR2(1) := 'C';
    g_flg_code_type_u CONSTANT VARCHAR2(1) := 'U';
    g_exception EXCEPTION;

    g_home_medication  sr_surgery_validation.flg_group%TYPE := 'HOME_MEDICATION';
    g_past_history     sr_surgery_validation.flg_group%TYPE := 'PAST_HISTORY';
    g_surgical_history sr_surgery_validation.flg_group%TYPE := 'SURGICAL_HISTORY';
    g_flg_type_get     sr_surgery_validation.flg_type%TYPE := 'G';

    g_filter_status_sr_reserv   table_varchar := table_varchar(g_flg_status_f);
    g_filter_status_sr_posit    table_varchar := table_varchar(g_flg_status_f);
    g_filter_status_sr_supplies table_varchar := table_varchar(pk_supplies_constant.g_sww_consumed,
                                                               pk_supplies_constant.g_sww_deliver_concluded,
                                                               pk_supplies_constant.g_sww_loaned,
                                                               pk_supplies_constant.g_sww_rejected_pharmacist);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_sr_clinical_info;
/
