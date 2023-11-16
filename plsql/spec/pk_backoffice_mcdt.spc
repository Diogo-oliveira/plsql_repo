/*-- Last Change Revision: $Rev: 2053703 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-21 13:17:49 +0000 (qua, 21 dez 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_mcdt IS

    -- Author  : TERCIO.SOARES
    -- Created : 23-11-2007 8:42:32
    -- Purpose : Parametrização de MCDT'S

    /********************************************************************************************
    * Get Analysis List
    *
    * @param i_lang            Prefered language ID
    * @param i_search_name     Search name
    * @param i_search_sample   Search sample
    * @param o_analysis_list   Analysis
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/23
    ********************************************************************************************/
    FUNCTION get_analysis_list
    (
        i_lang          IN language.id_language%TYPE,
        i_search_name   IN VARCHAR2,
        i_search_sample IN VARCHAR2,
        o_analysis_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis screen tasks list
    *
    * @param i_lang            Prefered language ID
    * @param o_list            Tasks
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/26
    ********************************************************************************************/
    FUNCTION get_analysis_possible_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis status list
    *
    * @param i_lang            Prefered language ID
    * @param o_analysis_state  Status
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/26
    ********************************************************************************************/
    FUNCTION get_analysis_state_list
    (
        i_lang           IN language.id_language%TYPE,
        o_analysis_state OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update Analysis Status
    *
    * @param i_lang            Prefered language ID
    * @param i_id_analysis     Analysis ID
    * @param i_flg_available   Status
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2007/11/26
    ********************************************************************************************/
    FUNCTION set_analysis_state
    (
        i_lang          IN language.id_language%TYPE,
        i_id_analysis   IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis Information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object (professional ID, institution ID, software ID)
    * @param i_id_analysis         Analysis ID
    * @param o_analysis            Analysis
    * @param o_analysis_parameter  Analysis parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2007/11/23
    ********************************************************************************************/
    FUNCTION get_analysis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_analysis        IN analysis.id_analysis%TYPE,
        o_analysis           OUT pk_types.cursor_type,
        o_analysis_parameter OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Find LOINC code
    *
    * @param i_lang           Prefered language ID
    * @param i_prof           Object (professional ID, institution ID, software ID)
    * @param i_loinc_code     LOINC code
    * @param o_loinc_list     LOINC
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2007/11/23
    ********************************************************************************************/
    FUNCTION find_loinc_code
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_loinc_code IN analysis_loinc_template.loinc_code%TYPE,
        o_loinc_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Sample Type List
    *
    * @param i_lang           Prefered language ID
    * @param o_loinc_list     Sample types
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2007/11/23
    ********************************************************************************************/
    FUNCTION get_sample_type_list
    (
        i_lang             IN language.id_language%TYPE,
        o_sample_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get sample recipient list
    *
    * @param i_lang           Prefered language ID
    * @param i_search         Search
    * @param o_recipient_list Sample recipients
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2007/11/23
    ********************************************************************************************/
    FUNCTION get_sample_recipient_list
    (
        i_lang           IN language.id_language%TYPE,
        i_search         IN VARCHAR2,
        o_recipient_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Software's Analysis Sample Recipient List
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_soft_recipient_list   Sample recipients
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2007/11/27
    ********************************************************************************************/
    FUNCTION get_soft_recipient_list
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN analysis_param.id_institution%TYPE,
        i_id_software         IN table_number,
        o_soft_recipient_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Set New Sample Recipient OR Update Recipient Information
    * 
    * @param      I_LANG                        Identificação do Idioma
    * @param      I_ID_SAMPLE_RECIPIENT         Identificação do Recipiente
    * @param      I_DESC                        Designação do Recipiente
    * @param      I_CAPACITY                    Capacidade
    * @param      I_CODE_CAPACITY_MEASURE       Código para tradução da unidade de medida da capacidade
    * @param      O_ID_SAMPLE_RECIPIENT         Identificação do Recipiente
    * @param      O_ERROR                       Erro
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION set_sample_recipient
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_sample_recipient   IN sample_recipient.id_sample_recipient%TYPE,
        i_desc                  IN VARCHAR2,
        i_flg_available         IN sample_recipient.flg_available%TYPE,
        i_capacity              IN sample_recipient.capacity%TYPE,
        i_code_capacity_measure IN sample_recipient.code_capacity_measure%TYPE,
        o_id_sample_recipient   OUT sample_recipient.id_sample_recipient%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Analysis OR Update Analysis Information
    *
    * @param      I_LANG                               Identificação do Idioma
    * @param      I_PROF                               professional, institution and software ids
    * @param      I_ID_ANALYSIS                        Identificação da Análise
    * @param      I_DESC                               Designação da Análise
    * @param      I_FLG_AVAILABLE                      Disponibilidade
    * @param      I_SAMPLE_TYPE                        Tipo de Análise
    * @param      I_GENDER                             Género
    * @param      I_AGE_MIN                            Idade mínima para realizar análise
    * @param      I_AGE_MAX                            Idade máxima para realizar análise
    * @param      I_MDM_CODING                         Codificação MDM
    * @param      I_CPT_CODE                           Código CPT
    * @param      I_LOINC                              Códigos LOINC
    * @param      O_ID_ANALYSIS                        Identificação da Análise    
    * @param      I_ANALYSIS_LOINC                     Ids da relação dos códigos LOINC com a análise
    * @param      O_ERROR                              Erro 
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/03/22
    */
    FUNCTION set_analysis
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_analysis               IN analysis.id_analysis%TYPE,
        i_desc                      IN VARCHAR2,
        i_flg_available             IN analysis.flg_available%TYPE,
        i_id_sample_type            IN analysis.id_sample_type%TYPE,
        i_gender                    IN analysis.gender%TYPE,
        i_age_min                   IN analysis.age_min%TYPE,
        i_age_max                   IN analysis.age_max%TYPE,
        i_mdm_coding                IN VARCHAR2,
        i_cpt_code                  IN VARCHAR2,
        i_loinc                     IN table_number,
        i_analysis_parameter        IN table_number,
        i_analysis_parameter_change IN table_varchar,
        o_id_analysis               OUT analysis.id_analysis%TYPE,
        o_analysis_loinc            OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_analysis_parameter_count
    (
        i_lang                     IN language.id_language%TYPE,
        i_search                   IN VARCHAR2,
        o_analysis_parameter_count OUT NUMBER,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Parameter List
    * 
    * @param      I_LANG                       Identificação do Idioma
    * @param      O_ANALYSIS_PARAMETER_LIST    Cursor com a Informação da Listagem das Análises
    * @param      O_ERROR                      Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/23
    */

    FUNCTION get_analysis_parameter_list
    (
        i_lang                    IN language.id_language%TYPE,
        i_search                  IN VARCHAR2,
        i_start_record            IN NUMBER DEFAULT NULL,
        i_num_records             IN NUMBER DEFAULT NULL,
        o_analysis_parameter_list OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Analysis Parameter OR Update Analysis Parameter Information
    *
    * @param      I_LANG                               Identificação do Idioma
    * @param      I_PROF                               professional, institution and software ids
    * @param      I_ID_ANALYSIS_PARAMETER              Identificação do Parametro de Análises
    * @param      I_DESC                               Designação do Parametro de Análises
    * @param      I_FLG_AVAILABLE                      Disponibilidade
    * @param      O_ID_ANALYSIS_PARAMETER              Identificação do Parametro de Análises 
    * @param      O_ERROR                              Erro 
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION set_analysis_parameter
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_desc                  IN VARCHAR2,
        i_flg_available         IN analysis.flg_available%TYPE,
        o_id_analysis_parameter OUT analysis_parameter.id_analysis_parameter%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Groups List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_ANALYSIS_GROUP_LIST      Cursor com a Informação da Listagem dos Grupos de Análises
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION get_analysis_group_list
    (
        i_lang                IN language.id_language%TYPE,
        i_search              IN VARCHAR2,
        o_analysis_group_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Group POSSIBLE LIST
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_LIST                     Tarefas possíveis no botão de adicionar no ecra de análises
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_analysis_group_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Groups List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_ANALYSIS_GROUP        Identificação do grupo de análises
    * @param      O_GROUP_ANALYSIS           Cursor com a Informação da Listagem de Análises do grupo
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION get_group_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_id_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_search            IN VARCHAR2,
        o_group_analysis    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Analysis Group OR Update Analysis Group Information
    *
    * @param      I_LANG                               Identificação do Idioma
    * @param      I_PROF                               professional, institution and software ids
    * @param      I_ANALYSIS_GROUP                     Identificação do Grupo de Análises
    * @param      I_DESC_GROUP                         Descritivo do Grupo de Análises
    * @param      I_GENDER                             Género ao qual se aplica o grupo
    * @param      I_AGE_MIN                            Idade mínima ao qual se aplica o grupo
    * @param      I_AGE_MAX                            Idade máxima ao qual se aplica o grupo
    * @param      I_ANALYSIS_AGP                       Identificação das análises para os grupos
    * @param      O_ANALYSIS_GROUP                     Identificação do Grupo de Análises
    * @param      I_ANALYSIS_AGP                       Identificação da relação  Grupo - Análises
    * @param      O_ERROR                              Erro 
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/11/23
    */
    FUNCTION set_group_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_analysis_group IN analysis_agp.id_analysis_group%TYPE,
        i_desc_group        IN VARCHAR2,
        i_gender            IN analysis_group.gender%TYPE,
        i_age_min           IN analysis_group.age_min%TYPE,
        i_age_max           IN analysis_group.age_max%TYPE,
        i_analysis          IN table_number,
        i_analysis_change   IN table_varchar,
        o_id_analysis_group OUT analysis_group.id_analysis_group%TYPE,
        o_id_analysis_agp   OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Software Analysis List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Insituição
    * @param      O_ANALYSIS_GROUP_LIST      Cursor com a Informação da Listagem dos Grupos de Análises
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_inst_soft_analysis_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_search         IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis POSSIBLE LIST
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_LIST                     Tarefas possíveis no botão de adicionar no ecra de análises
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_inst_analysis_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Institution Analysis List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Insituição
    * @param      I_ID_ANALYSIS              Identificação da Análise
    * @param      I_PROF                     Profissional
    * @param      O_INST_ANALYSIS            Cursor com a Informação da Análise
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    */
    FUNCTION get_inst_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_institution         IN analysis_instit_soft.id_institution%TYPE,
        i_id_analysis            IN analysis_instit_soft.id_analysis%TYPE,
        i_id_software            IN analysis_instit_soft.id_software%TYPE,
        i_prof                   IN profissional,
        o_inst_analysis          OUT pk_types.cursor_type,
        o_inst_analysis_param    OUT pk_types.cursor_type,
        o_inst_analysis_recep    OUT pk_types.cursor_type,
        o_inst_analysis_workflow OUT pk_types.cursor_type,
        o_flg_rec_lab            OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Institution Analysis Information
    *
    * @param i_lang                       Prefered language ID
    * @param i_id_institution             Institution ID
    * @param i_id_analysis                Analysis ID
    * @param i_id_software                Software ID
    * @param i_prof                       Object
    * @param o_inst_analysis              Cursor with analysis information                      
    * @param o_inst_analysis_sin          Synonim
    * @param o_inst_analysis_loinc        Loinc Codes
    * @param o_inst_analysis_cat          Categories
    * @param o_inst_analysis_param        Parameterd
    * @param o_inst_analysis_lab          Rooms
    * @param o_inst_analysis_lab_recep    Recipients
    * @param o_inst_analysis_wf_harvest   Harvest
    * @param o_inst_analysis_wf_mv_pat    Move patient
    * @param o_inst_analysis_wf_mv_rec    Move recipient
    * @param o_inst_analysis_wf_exec      Execution
    * @param o_inst_analysis_wf_result    First result
    * @param o_inst_analysis_lab_app_req  Lab approval required
    * @param o_inst_analysis_lab_ap_by    Lab approval by
    * @param o_inst_analysis_lab_exe_by   Lab executed by
    * @param o_inst_analysis_pat_ap_req   Patient approval required
    * @param o_inst_analysis_timing       Timing of questionnaire
    * @param o_inst_analysis_prim_res_vis Primary results visible to requester
    * @param o_inst_analysis_lab_quest    Questionnaire
    * @param o_flg_rec_lab                Recipient dependes on lab
    * @param o_inst_analysis_coll         Analysis collection   
    * @param o_inst_analysis_coll_int     Analysis collection interval
    * @param o_inst_analysis_coll_def_int Default collection interval           
    * @param o_error                      Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           JTS
    * @version                          0.1
    * @since                            2008/05/18
    ********************************************************************************************/
    FUNCTION get_inst_analysis_all
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_analysis                IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type             IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_institution             IN analysis_instit_soft.id_institution%TYPE,
        i_id_software                IN analysis_instit_soft.id_software%TYPE,
        o_inst_analysis              OUT pk_types.cursor_type,
        o_inst_analysis_sin          OUT pk_types.cursor_type,
        o_inst_analysis_loinc        OUT pk_types.cursor_type,
        o_inst_analysis_cat          OUT pk_types.cursor_type,
        o_inst_analysis_param        OUT pk_types.cursor_type,
        o_inst_analysis_lab          OUT pk_types.cursor_type,
        o_inst_analysis_lab_recep    OUT pk_types.cursor_type,
        o_inst_analysis_wf_harvest   OUT pk_types.cursor_type,
        o_inst_analysis_wf_mv_pat    OUT pk_types.cursor_type,
        o_inst_analysis_wf_mv_rec    OUT pk_types.cursor_type,
        o_inst_analysis_wf_exec      OUT pk_types.cursor_type,
        o_inst_analysis_wf_result    OUT pk_types.cursor_type,
        o_inst_analysis_room_mv_pat  OUT pk_types.cursor_type,
        o_inst_analysis_dupl_warn    OUT pk_types.cursor_type,
        o_inst_analysis_lab_quest_o  OUT pk_types.cursor_type,
        o_inst_analysis_lab_quest_c  OUT pk_types.cursor_type,
        o_flg_rec_lab                OUT VARCHAR2,
        o_inst_analysis_coll         OUT pk_types.cursor_type,
        o_inst_analysis_coll_int     OUT pk_types.cursor_type,
        o_inst_analysis_coll_def_int OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get timing order
    *
    * @param i_lang                     Prefered language ID
    * @param o_timing                   Cursor with all timing order for the institution                      
    * 
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           MARCO FREIRE
    * @version                          0.1
    * @since                            2010/05/18
    ********************************************************************************************/
    FUNCTION get_timing
    (
        i_lang   IN language.id_language%TYPE,
        o_timing OUT pk_types.cursor_type,
        o_error  OUT t_error_out
        
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_ANALYSIS_QUESTIONARY
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_analysis              Analysis ID                      
    * @param i_id_institution           Institution ID
    * @param i_val                      Desc Val on Sys_domain
    * @param o_inst_analysis_lab_quest  Cursor with questions
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           MARCO FREIRE
    * @version                          0.1
    * @since                            2010/06/21
    ********************************************************************************************/
    FUNCTION get_analysis_questionnaire
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_analysis             IN analysis.id_analysis%TYPE,
        i_id_sample_type          IN sample_type.id_sample_type%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_val                     IN sys_domain.desc_val%TYPE,
        o_inst_analysis_lab_quest OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Software list
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_LIST                     Lista de aplicações
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    */
    FUNCTION get_software_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Software's Analysis Parameter List
    * 
    * @param      I_LANG                       Identificação do Idioma
    * @param      I_ID_INSTITUTION             Identificação da Instituição
    * @param      I_ID_SOFTWARE                Identificação da Aplicação
    * @param      O_SOFT_PARAMETER_LIST        Cursor com a Informação da Listagem dos parametros
    * @param      O_ERROR                      Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    */
    FUNCTION get_soft_parameter_list
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN analysis_param.id_institution%TYPE,
        i_id_software         IN table_number,
        o_soft_parameter_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_analysis_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Department Information List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Instituição
    * @param      O_DEPT                     Cursor com a Informação dos Departamentos
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2008/01/09
    */
    FUNCTION get_dept_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_context        IN VARCHAR2,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Department Information List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Instituição
    * @param      O_DEPT                     Cursor com a Informação dos Departamentos
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2008/01/24
    */
    FUNCTION get_dept_group_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Software's Analysis Parameter List
    * 
    * @param      I_LANG                       Identificação do Idioma
    * @param      I_ID_DEPT                    Identificação do Departamento
    * @param      I_ID_INSTITUTION             Identificação da Instituição
    * @param      O_SERVICE_LIST               Cursor com a Informação da Listagem dos serviços
    * @param      O_ERROR                      Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    */
    FUNCTION get_dept_dcs_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        i_id_institution IN department.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_context        IN VARCHAR2,
        i_prof           IN profissional,
        o_service_list   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Institution Dep. Clinical Service Analysis List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_DEP_CLIN_SERV         Identificação do Dept/Serviço clínico
    * @param      I_ID_SOFTWARE              Identificação do Software
    * @param      O_ANALYSIS_DCS_LIST        Cursor com a Informação da Listagem das análises mais freq.
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_analysis_dcs_list
    (
        i_lang              IN language.id_language%TYPE,
        i_id_dep_clin_serv  IN analysis_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_software       IN analysis_dep_clin_serv.id_software%TYPE,
        i_id_institution    IN analysis_instit_soft.id_institution%TYPE,
        o_analysis_dcs_list OUT pk_types.cursor_type,
        o_group_dcs_list    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Relation(Department/Clinical Service) Information
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Instituição
    * @param      I_ID_ANALYSIS              Identificação da Análise
    * @param      O_REL                      Cursor com a Informação da Relação(Departamento/Serviço clínico)
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/11/30
    */
    FUNCTION get_dep_clin_serv
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
        o_rel            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Exam Category list
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_LIST                     Lista de aplicações
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/11/27
    */
    FUNCTION get_exam_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Analysis Group OR Update Analysis Group Information
    *
    * @param      I_LANG                               Identificação do Idioma
    * @param      I_PROF                               professional, institution and software ids
    * @param      I_ID_SOFTWARE                        Identificação da aplicação
    * @param      I_DEP_CLIN_SERV                      Array de Dep/Clin.Serv
    * @param      I_ANALYSIS                           Array de arrays de Identificação de Análises
    * @param      I_PANELS                             Array de arrays de Identificação de Painéis
    * @param      I_SELECT                             Array de arrays de indicação de inserção ou remoção
    * @param      O_ID_ANALYSIS_DEP_CLIN_SERV          Identificação das relações de Dep/Clin Serv
    * @param      I_ANALYSIS_AGP                       Identificação da relação  Grupo - Análises
    * @param      O_ERROR                              Erro 
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/12/13
    */
    FUNCTION set_analysis_dcs
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_institution            IN institution.id_institution%TYPE,
        i_id_software               IN software.id_software%TYPE,
        i_dep_clin_serv             IN table_number,
        i_analysis                  IN table_table_number,
        i_panels                    IN table_table_number,
        i_select                    IN table_table_varchar,
        i_commit_at_end             IN VARCHAR2,
        o_id_analysis_dep_clin_serv OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Update Sample Recipient State
    *
    * @param      I_LANG                               Identificação do Idioma
    * @param      I_ID_SAMPLE_RECIPIENT                Identificação do Recipiente
    * @param      I_FLG_AVAILABLE                      Estado: Activo / Inactivo
    * @param      O_ERROR                              Erro 
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/13
    */
    FUNCTION set_recipient_state
    (
        i_lang                IN language.id_language%TYPE,
        i_id_sample_recipient IN table_number,
        i_flg_available       IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Sample Recipient POSSIBLE LIST
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_LIST                     Tarefas possíveis no botão de adicionar no ecra Recipientes
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/13
    */
    FUNCTION get_recipient_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Recipient State List
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_RECIPIENT_STATE         Cursor com a Informação dos estados do recipiente
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/13
    */
    FUNCTION get_recipient_state_list
    (
        i_lang            IN language.id_language%TYPE,
        o_recipient_state OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Sample Recipient Information
    * 
    * @param      I_LANG                        Identificação do Idioma
    * @param      I_ID_SAMPLE_RECIPIENT         Identificação do Recipiente
    * @param      O_RECIPIENT                   Cursor com a informação relativa ao Recipiente
    * @param      O_ERROR                       Erro
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/12/13
    */
    FUNCTION get_sample_recipient
    (
        i_lang                IN language.id_language%TYPE,
        i_id_sample_recipient IN sample_recipient.id_sample_recipient%TYPE,
        o_recipient           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Group State LIST
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_LIST                     Estados possíveis no ecra de análises dos paineis
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/14
    */
    FUNCTION get_analysis_group_state_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Find Analysis Alias
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     Professional, institution and software ids
    * @param      I_ID_INSTITUTION           Identificação da instituição
    * @param      I_ID_ANALYSIS              Identificação da análise
    * @param      O_ALIAS_LIST               Lista de Sinónimos
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/18
    */
    FUNCTION find_analysis_alias
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN analysis_alias.id_institution%TYPE,
        i_id_analysis    IN analysis_alias.id_analysis%TYPE,
        o_alias_list     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Groups List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_ANALYSIS_GROUP        Identificação do grupo de análises
    * @param      I_GENDER                   Género
    * @param      I_AGE_MIN                  Idade Mínima
    * @param      I_AGE_MAX                  Idade Máxima
    * @param      O_LITS                     Cursor com a Informação da Listagem de Análises
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/18
    */
    FUNCTION get_agp_criteria_list
    (
        i_lang              IN language.id_language%TYPE,
        i_id_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_gender            IN analysis_group.gender%TYPE,
        i_age_min           IN analysis_group.age_min%TYPE,
        i_age_max           IN analysis_group.age_max%TYPE,
        i_search            IN VARCHAR2,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Group Information
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_ANALYSIS_GROUP        Identificação do grupo de análises
    * @param      O_ANALYSIS_GROUP           Cursor com a Informação do Grupo de Análises
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/18
    */
    FUNCTION get_analysis_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_analysis_group IN analysis_group.id_analysis_group%TYPE,
        o_analysis_group    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Gender List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_GENDER                   Cursor com a Informação dos Géneros
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/20
    */
    FUNCTION get_gender_list
    (
        i_lang   IN language.id_language%TYPE,
        o_gender OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Update Parameter State
    *
    * @param      I_LANG                               Identificação do Idioma
    * @param      I_ID_PARAMETER                       Identificação do parâmetro
    * @param      I_FLG_AVAILABLE                      Estado: Activo / Inactivo
    * @param      O_ERROR                              Erro 
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    */
    FUNCTION set_parameter_state
    (
        i_lang          IN language.id_language%TYPE,
        i_id_parameter  IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Institution Type List
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_ANALYSIS_STATE           Cursor com a Informação dos estados da análise
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    */
    FUNCTION get_parameter_state_list
    (
        i_lang            IN language.id_language%TYPE,
        o_parameter_state OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Parameter POSSIBLE LIST
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      O_LIST                     Tarefas possíveis no botão de adicionar no ecra Parâmetros
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    */
    FUNCTION get_parameter_poss_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Analysis Parameter Information
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_PROF                     professional, institution and software ids
    * @param      I_ID_PARAMETER             Identificação do Parâmetro
    * @param      O_PARAMETER                Cursor com a Informação do Parâmetro
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2007/12/24
    */
    FUNCTION get_parameter_details
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_parameter    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Dep_clin_serv List
    * 
    * @param      I_LANG                       Identificação do Idioma
    * @param      I_ID_DEPT                    Identificação do Departamento
    * @param      I_ID_INSTITUTION             Identificação da Instituição
    * @param      O_SERVICE_LIST               Cursor com a Informação da Listagem dos serviços
    * @param      O_ERROR                      Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/01/24
    */
    FUNCTION get_dept_dcs_group_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        i_id_institution IN department.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_service_list   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Interventions list
    *
    * @param i_lang                  Prefered language ID
    * @param o_interv_list           Interventions
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/23
    ********************************************************************************************/
    FUNCTION get_intervention_list
    (
        i_lang        IN language.id_language%TYPE,
        i_search      IN VARCHAR2,
        o_interv_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update Interventions state
    *
    * @param i_lang                Prefered language ID
    * @param i_id_interv           Interventions ID's
    * @param i_flg_available       A - available ; I - not available
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/16
    ********************************************************************************************/
    FUNCTION set_interventions_state
    (
        i_lang          IN language.id_language%TYPE,
        i_id_interv     IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get POSSIBLE LIST
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                Options
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_poss_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Intervention information
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Object (professional ID, institution ID, software ID)
    * @param i_id_intervention     Intervention ID
    * @param o_intervention        Intervention information
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_intervention
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        o_intervention    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Body Parts
    *
    * @param i_lang                Prefered language ID
    * @param o_body_part           Body Part List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_body_part_list
    (
        i_lang      IN language.id_language%TYPE,
        o_body_part OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Specialties System Appar
    *
    * @param i_lang                Prefered language ID
    * @param o_spec_sys_appar      Spec_sys_appr List
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_spec_sys_appar_list
    (
        i_lang           IN language.id_language%TYPE,
        o_spec_sys_appar OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Intervention Phys. Area
    *
    * @param i_lang                Prefered language ID
    * @param o_interv_phys_area    Intervention Phys. Areas
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_interv_phys_area_list
    (
        i_lang             IN language.id_language%TYPE,
        o_interv_phys_area OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get State List
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                List od states
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/28
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Institution Dep. Clinical Service Interventions List
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_DEP_CLIN_SERV         Identificação do Dept/Serviço clínico
    * @param      I_ID_SOFTWARE              Identificação do Software
    * @param      O_INTERV_DCS_LIST          Cursor com a Informação da Listagem dos intervenções mais freq.
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     JTS
    * @version    0.1
    * @since      2008/04/22
    */
    FUNCTION get_interv_dcs_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_software      IN interv_dep_clin_serv.id_software%TYPE,
        i_id_institution   IN interv_dep_clin_serv.id_institution%TYPE,
        o_interv_dcs_list  OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Interventions/Dep_clin_serv association
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_interv                Arrya of array of Interventions ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param i_commit_at_end         Commit (Y - Yes; N - No)
    * @param o_id_interv_dep_clin_serv Associations ID's
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/23
    ********************************************************************************************/
    FUNCTION set_interv_dcs
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_dep_clin_serv           IN table_number,
        i_interv                  IN table_table_number,
        i_select                  IN table_table_varchar,
        i_commit_at_end           IN VARCHAR2,
        o_id_interv_dep_clin_serv OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Most Frequent software list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param o_software              Software List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/23
    ********************************************************************************************/
    FUNCTION get_software_dcs
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * New Intervention OR Update Intervention Information
    *
    * @param i_lang                     Prefered language ID
    * @param i_prof                     Object
    * @param i_id_intervention          Intervention ID
    * @param i_id_intervention_parent   Parent Intervention ID
    * @param i_desc                     Intervention Name
    * @param i_flg_status               A - available ; I - not available
    * @param i_id_body_part             Body Part
    * @param i_id_spec_sys_appar        System/Specialty ID
    * @param i_id_interv_physiatry_area Physiatry area ID
    * @param i_gender                   Gender
    * @param i_age_min                  Minimum age
    * @param i_age_max                  Maximum age
    * @param i_mdm_coding               MDM code
    * @param i_cpt_code                 CPT code
    * @param i_flg_mov_pat              Move patient?
    * @param o_id_intervention          Intervention ID
    * @param o_error                    Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION set_intervention
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_intervention        IN intervention.id_intervention%TYPE,
        i_desc                   IN VARCHAR2,
        i_flg_status             IN intervention.flg_status%TYPE,
        i_id_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_interv_cat             IN interv_category.id_interv_category%TYPE,
        i_mdm_coding             IN intervention.mdm_coding%TYPE,
        i_cpt_code               IN intervention.cpt_code%TYPE,
        i_gender                 IN intervention.gender%TYPE,
        i_age_min                IN intervention.age_min%TYPE,
        i_age_max                IN intervention.age_max%TYPE,
        i_flg_mov_pat            IN intervention.flg_mov_pat%TYPE,
        o_id_intervention        OUT intervention.id_intervention%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Interventions by Institution and Software
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_inst_soft_interv_list Exams list
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION get_inst_soft_interv_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_search         IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get My Alert Association
    *
    * @param i_lang                  Prefered language ID
    * @param i_dep_clin_serv         Service/Clinical Service ID
    * @param i_id_software           Software ID
    * @param i_id_institution        Institution ID
    * @param i_context               Context (A - Analysis, G - Analysis Groups, ...)
    * @param i_search                Filtro de pesquisa
    * @param i_id_diagnosis          Diagnosis ID
    * @param o_dcs_list              My Alert list
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/30
    ********************************************************************************************/
    FUNCTION get_my_alert_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN NUMBER,
        i_id_software      IN NUMBER,
        i_id_institution   IN NUMBER,
        i_context          IN VARCHAR2,
        i_search           IN VARCHAR2,
        i_id_diagnosis     IN diagnosis.id_diagnosis%TYPE,
        o_dcs_list         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * My alert association
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_context               Context
    * @param i_my_alert_id           Array of array of My Alert ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/30
    ********************************************************************************************/
    FUNCTION set_my_alert
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_dep_clin_serv  IN table_number,
        i_context        IN VARCHAR2,
        i_my_alert_id    IN table_table_varchar,
        i_select         IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Institution Searchable List
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_software              Software ID's
    * @param i_context               Context (A - Analysis, G - Analysis Groups, ...)
    * @param i_search                Search filter
    * @param o_inst_pesq_list        List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/06
    ********************************************************************************************/
    FUNCTION get_inst_pesq_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_context        IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis Category List
    *
    * @param i_lang                  Prefered language ID
    * @param o_list                  List of analysis categories
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/07
    ********************************************************************************************/
    FUNCTION get_analysis_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Analysis Types in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_id_institution  Institution ID
    * @param i_software        Softwares ID's
    * @param i_analysis        Analysis ID's
    * @param i_flg_type        Analysis Types
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/05/08
    ********************************************************************************************/
    FUNCTION set_inst_soft_analysis_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_analysis       IN table_table_number,
        i_sample_type    IN table_table_number,
        i_flg_type       IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Most Frequent dept list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param o_dept_list             Dept List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/09
    ********************************************************************************************/
    FUNCTION get_software_dept_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Service Room list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_department         Service ID
    * @param o_room_list             Room List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/13
    ********************************************************************************************/
    FUNCTION get_department_room_list
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_room_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Labs list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_software           Software ID
    * @param i_id_analysis           Analysis ID
    * @param o_room_list             Room List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/13
    ********************************************************************************************/
    FUNCTION get_lab_room_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        o_room_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Analysis Labs list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_analysis           Analysis ID
    * @param i_search                Search
    * @param o_lab_list              Lab List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/19
    ********************************************************************************************/
    FUNCTION get_analysis_lab_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        i_search         IN VARCHAR2,
        o_lab_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Analysis sample recipient list
    *
    * @param i_lang           Prefered language ID
    * @param i_id_institution Institution ID
    * @param i_id_software    Software ID
    * @param i_id_analysis    Analysis ID
    * @param i_search         Search
    * @param o_recipient_list Sample recipients
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2008/05/13
    ********************************************************************************************/
    FUNCTION get_analysis_recipient_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        i_id_room        IN analysis_room.id_room%TYPE,
        i_search         IN VARCHAR2,
        o_recipient_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Loinc list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_analysis           Analysis ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    * @param i_search                Search
    * @param o_loinc_list            Loinc List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/21
    ********************************************************************************************/
    FUNCTION get_analysis_loinc_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_analysis    IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_search         IN VARCHAR2,
        o_loinc_list     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Service lab list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_department         Service ID
    * @param o_lab_list              Lab List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/23
    ********************************************************************************************/
    FUNCTION get_service_lab_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institutiton IN institution.id_institution%TYPE,
        i_id_department   IN department.id_department%TYPE,
        o_lab_list        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Institution Interventions Information
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution           Institution ID
    * @param i_id_analysis              Analysis ID
    * @param i_id_software              Software ID
    * @param i_prof                     Object
    * @param o_inst_interv              Intervention information
    * @param o_inst_analysis_wf_bandaid Bandaid
    * @param o_inst_analysis_wf_charge  Chargeble intervention?
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           JTS
    * @version                          0.1
    * @since                            2008/05/24
    ********************************************************************************************/
    FUNCTION get_inst_interv_all
    (
        i_lang                      IN language.id_language%TYPE,
        i_id_institution            IN interv_dep_clin_serv.id_institution%TYPE,
        i_id_intervention           IN interv_dep_clin_serv.id_intervention%TYPE,
        i_id_software               IN interv_dep_clin_serv.id_software%TYPE,
        i_prof                      IN profissional,
        o_inst_interv               OUT pk_types.cursor_type,
        o_inst_interv_wf_bandaid    OUT pk_types.cursor_type,
        o_inst_interv_wf_chargeable OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Institution intervention parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_intervention       Intervention ID
    * @param i_id_institution        Institution ID
    * @param i_interv_cat_SOFT       [Interv_categoty ID, Software ID]
    * @param i_id_software           Software ID's
    * @param i_flg_bandais           Bandaid flags
    * @param i_flg_chargeable        Chargeable flags
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/24
    ********************************************************************************************/
    FUNCTION set_inst_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN interv_dep_clin_serv.id_intervention%TYPE,
        i_id_institution  IN interv_dep_clin_serv.id_institution%TYPE,
        i_id_software     IN table_number,
        i_flg_bandaid     IN table_varchar,
        i_flg_chargeable  IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Institution analysis parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_analysis           Analysis ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID's
    * @param i_syn                   Analysis synonim
    * @param i_id_exam_cat           Analysis categories
    * @param i_loinc                 Loinc codes
    * @param i_loinc_default         Default Loinc
    * @param i_loinc_select          Loinc selection indication
    * @param i_parameters            Parameters
    * @param i_parameters_select     Parameters selection indication
    * @param i_lab                   Lab ID's
    * @param i_lab_default           Default lab
    * @param i_lab_select            Labs selection indication
    * @param i_flg_rec_lab           Recipient depends on lab?
    * @param i_recipient             Recipient ID's
    * @param i_recipient_default     Default recipient
    * @param i_recipient_select      Recipient selection indication
    * @param i_recipient_room        Recipient rooms
    * @param i_room_mov_pat          Room to move patient
    * @param i_flg_mov_pat           Move patient flags
    * @param i_flg_mov_rec           Move recipient flags
    * @param i_flg_harvest           Harvest flags
    * @param i_flg_first_res         First result flags
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/24
    ********************************************************************************************/
    FUNCTION set_inst_analysis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_analysis        IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type     IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_institution     IN analysis_instit_soft.id_institution%TYPE,
        i_id_software        IN table_number,
        i_syn                IN table_varchar,
        i_id_exam_cat        IN table_number,
        i_loinc              IN table_table_varchar,
        i_loinc_default      IN table_table_varchar,
        i_loinc_select       IN table_table_varchar,
        i_parameters         IN table_table_number,
        i_parameters_select  IN table_table_varchar,
        i_lab                IN table_table_number,
        i_lab_default        IN table_table_varchar,
        i_lab_select         IN table_table_varchar,
        i_flg_rec_lab        IN VARCHAR2,
        i_recipient          IN table_table_number,
        i_recipient_default  IN table_table_varchar,
        i_recipient_select   IN table_table_varchar,
        i_recipient_room     IN table_table_number,
        i_room_mov_pat       IN analysis_room.id_room%TYPE,
        i_flg_mov_pat        IN table_varchar,
        i_flg_mov_rec        IN table_varchar,
        i_flg_harvest        IN analysis_instit_soft.flg_harvest%TYPE,
        i_flg_first_res      IN table_varchar,
        i_flg_duplicate_warn IN table_varchar,
        i_tbl_id_room_quest  IN table_number,
        i_tbl_timing         IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Institution Exams Information
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution           Institution ID
    * @param i_id_exam                  Exam ID
    * @param i_id_software              Software ID
    * @param i_prof                     Object
    * @param o_inst_exam                Exam information
    * @param o_inst_exam_wf_mv_pat      Move patient?
    * @param o_inst_exam_wf_result      First result
    * @param o_inst_exam_room           Exam room
    * @param o_error                    Error
    *
    *
    * @return                           true or false on success or error
    *
    * @author                           JTS
    * @version                          0.1
    * @since                            2008/05/24
    ********************************************************************************************/
    FUNCTION get_inst_exam_all
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN interv_dep_clin_serv.id_institution%TYPE,
        i_id_exam             IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_software         IN interv_dep_clin_serv.id_software%TYPE,
        i_prof                IN profissional,
        o_inst_exam           OUT pk_types.cursor_type,
        o_inst_exam_wf_mv_pat OUT pk_types.cursor_type,
        o_inst_exam_wf_result OUT pk_types.cursor_type,
        o_inst_exam_room      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Institution exam parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_exam               Exam ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID's
    * @param i_flg_mv_pat            Array - Move Patient flags
    * @param i_room                  Array - Move Patient rooms
    * @param i_first_result          Array - First to regist result
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/24
    ********************************************************************************************/
    FUNCTION set_inst_exam
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_institution IN exam_dep_clin_serv.id_institution%TYPE,
        i_id_software    IN table_number,
        i_flg_mv_pat     IN table_varchar,
        i_room           IN table_number,
        i_first_result   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Exams by Institution and Software
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_flg_imagem          I - Image exams ; O - Other exams
    * @param i_search              Search
    * @param o_inst_soft_exam_list Exams list
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/04/29
    ********************************************************************************************/
    FUNCTION get_inst_soft_exam_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id_software    IN analysis_instit_soft.id_software%TYPE,
        i_flg_image      IN VARCHAR2,
        i_search         IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Analysis Types in different softwares
    *
    * @param i_lang            Prefered language ID
    * @param i_id_institution  Institution ID
    * @param i_software        Software ID
    * @param i_mcdt            Analysis ID / Exam ID / Intervention ID
    * @param i_flg_type        Types
    * @param i_context         Analysis - A / Exam - E / Intervention - I
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/05/08
    ********************************************************************************************/
    FUNCTION set_inst_soft_mcdt_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN software.id_software%TYPE,
        i_mcdt           IN VARCHAR2,
        i_flg_type       IN VARCHAR2,
        i_context        IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Interventions categories
    *
    * @param i_lang            Prefered language ID
    * @param o_list            Categories list
    * @param o_error           Error
    *
    *
    * @return                  true or false on success or error
    *
    * @author                  JTS
    * @version                 0.1
    * @since                   2008/05/29
    ********************************************************************************************/
    FUNCTION get_interv_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Verify MCDT's missing data
    *
    * @param i_lang                  Prefered language ID
    * @param i_mcdt                  Analysis ID / Exams ID / Interventions ID
    * @param i_id_institution        Institution ID
    * @param i_context               Context (A - Analysis, G - Analysis Groups, ...)
    *
    *
    * @return                      NULL or MISSING DATA
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/06/01
    ********************************************************************************************/
    FUNCTION get_missing_data
    (
        i_lang           IN language.id_language%TYPE,
        i_mcdt           IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_context        IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get all sample recipient
    *
    * @param i_lang           Prefered language ID
    * @param i_search         Search
    * @param o_recipient_list Sample recipients
    * @param o_error          Error
    *
    *
    * @return                 true or false on success or error
    *
    * @author                 JTS
    * @version                0.1
    * @since                  2008/08/20
    ********************************************************************************************/
    FUNCTION get_sample_recipient_all
    (
        i_lang           IN language.id_language%TYPE,
        i_search         IN VARCHAR2,
        o_recipient_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get possible list for analysis workflow
    *
    * @param i_lang                Prefered language ID
    * @param o_list                cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2008/12/22
    ********************************************************************************************/
    FUNCTION get_analysis_yes_no_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_lab_test       IN analysis.id_analysis%TYPE,
        i_softs          IN table_number
    ) RETURN table_varchar;

    /********************************************************************************************
    * Get MCDT state in institution and software's
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id                    MCDT identification
    * @param i_software              Software ID's
    * @param i_context               Context
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'I' Image exams {*} 'O' Others Exams {*} 'P' Interventions   
    *                               {*} 'M' MFR Interventions
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.5.0.7.2
    * @since                       2009/11/11
    ********************************************************************************************/
    FUNCTION get_inst_pesq_state
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_id             IN VARCHAR2,
        i_software       IN table_number,
        i_context        IN VARCHAR2
    ) RETURN table_varchar;

    /********************************************************************************************
    * Set flags on Analysis Questionaire
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_analysis           Analysis ID
    * @param i_room                  Room ID
    * @param i_tbl_id_analysis_quest List of id questionnaires to be updated
    * @param i_tbl_val               List of flag values
    *
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MARCO FREIRE
    * @version                     2.6.0.3
    * @since                       2010/05/21
    ********************************************************************************************/
    FUNCTION set_lab_questionnaire
    (
        i_lang           IN language.id_language%TYPE,
        i_id_analysis    IN analysis.id_analysis%TYPE,
        i_id_sample_type IN sample_type.id_sample_type%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room_quest  IN room_questionnaire.id_room_questionnaire%TYPE,
        i_timing         IN analysis_questionnaire.flg_time%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get questionnaire
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_analysis           Analysis ID
    * @param i_id_exam               Exame ID
    * @param i_id_institution        Institution ID
    * @param i_id_room               Room ID
    *
    * @return                      true or false on success or error
    *
    * @author                      MARCO FREIRE
    * @version                     2.6.0.3
    * @since                       2010/05/28
    ********************************************************************************************/
    FUNCTION get_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        o_questionnaire OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Institution exam parametrization
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Object (professional ID, institution ID, software ID)
    * @param i_id_exam               Exam ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID's
    * @param i_flg_mv_pat            Array - Move Patient flags
    * @param i_room                  Exam room
    * @param i_first_result          Array - First to regist result
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2010/06/18
    ********************************************************************************************/
    FUNCTION set_inst_exam_new
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_institution IN exam_dep_clin_serv.id_institution%TYPE,
        i_id_software    IN table_number,
        i_flg_mv_pat     IN table_varchar,
        i_room           IN exam_room.id_room%TYPE,
        i_first_result   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set of a new Analysis Collection.
    *
    * @ param i_lang                     Preferred language ID for this professional 
    * @ param i_id_institution           Institution ID
    * @ param i_id_software              Software ID
    * @ param i_prof                     Object (professional ID, institution ID, software ID)    
    * @ param i_id_analysis              analysis ID    
    * @ param i_id_analysis_collection   analysis_collection ID            
    * @ param i_num_collection           Number of Collections 
    * @ param i_order_collection         Order of the Collection
    * @ param i_interval                 Interval of the Collection   
    * @ param i_flg_interval_type        Type Interval of the Collection        
    * @ param i_state                    Indication state (Y - active/N - Inactive)
    *
    * @param o_error                     Error
    *
    * @return                            true or false on success or error
    *
    * @author                            Teresa coutinho
    * @version                           2.6.1
    * @since                             2011/03/15
    **********************************************************************************************/
    FUNCTION set_analysis_collection
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution         IN analysis_instit_soft.id_institution%TYPE,
        i_id_software            IN table_number,
        i_id_analysis            IN analysis_instit_soft.id_analysis%TYPE,
        i_id_sample_type         IN analysis_instit_soft.id_sample_type%TYPE,
        i_id_analysis_collection IN table_number,
        i_num_collection         IN analysis_collection.num_collection%TYPE,
        i_order_collection       IN table_number,
        i_interval               IN table_number,
        i_flg_interval_type      IN analysis_collection.flg_interval_type%TYPE,
        i_state                  IN analysis_collection.flg_available%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @return                        Number of records
    *
    * @author                        RMGM
    * @since                         2011/06/28
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_num_records RETURN NUMBER;
    /********************************************************************************************
    * Get Institution Searchable List Number of records
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_software              Software ID's
    * @param i_context               Context
    * @param i_search                Search filter
    * @param o_inst_pesq_list        List
    * @param o_error                 Error
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'I' Image exams {*} 'O' Others Exams {*} 'P' Interventions   
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/06/28
    ********************************************************************************************/
    FUNCTION get_inst_pesq_list_count
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN analysis_instit_soft.id_institution%TYPE,
        i_software        IN table_number,
        i_context         IN VARCHAR2,
        i_search          IN VARCHAR2,
        o_inst_pesq_count OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Institution Searchable List Data
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_software              Software ID's
    * @param i_context               Context
    * @param i_search                Search filter
    * @param i_start_record          start record
    * @param i_num_records           number of records to show     
    * @param o_inst_pesq_list        List
    * @param o_error                 Error
    *
    *
    * @value     i_context          {*} 'A' Analyis {*} 'I' Image exams {*} 'O' Others Exams {*} 'P' Interventions   
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/06/28
    ********************************************************************************************/
    FUNCTION get_inst_pesq_list_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN analysis_instit_soft.id_institution%TYPE,
        i_software       IN table_number,
        i_context        IN VARCHAR2,
        i_search         IN VARCHAR2,
        i_start_record   IN NUMBER DEFAULT 1,
        i_num_records    IN NUMBER DEFAULT get_num_records,
        o_inst_pesq_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * check exam configuration
    *
    * @param i_id_exam            Exam ID
    * @param i_id_institution     Institution ID
    * @param i_flg_type           Type of configuration
    *
    *
    * @return                     number of results found
    *
    * @author                     RMGM
    * @version                    2.6.1
    * @since                      2013/04/05
    ********************************************************************************************/
    FUNCTION check_exam_config
    (
        i_id_exam        IN exam_dep_clin_serv.id_exam%TYPE,
        i_id_institution IN exam_dep_clin_serv.id_institution%TYPE,
        i_flg_type       IN exam_dep_clin_serv.flg_type%TYPE
    ) RETURN NUMBER;

    ---- Global Variables

    g_found        BOOLEAN;
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(2000);

    g_flg_available VARCHAR2(1);
    g_no            VARCHAR2(1);
    g_yes           VARCHAR2(1);

    g_status_i VARCHAR2(1);
    g_status_a VARCHAR2(1);

    g_analysis_flg_available  VARCHAR2(200);
    g_analysis_add_task       VARCHAR2(200);
    g_patient_gender          VARCHAR2(200);
    g_recipient_flg_available VARCHAR2(200);
    g_parameter_flg_available VARCHAR2(200);

    g_domain_gender VARCHAR2(200);

    g_hand_icon VARCHAR2(200);

    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

END pk_backoffice_mcdt;
/
