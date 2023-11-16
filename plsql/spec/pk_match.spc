/*-- Last Change Revision: $Rev: 2028789 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_match AS

    FUNCTION get_match_currepis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_curr           OUT pk_types.cursor_type,
        o_icon           OUT VARCHAR2,
        o_prof_nick_name OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função devolve um array com os dados do episódio actual (SE ESTE FOR TEMPORÁRIO)
                      que serão utilizados para a obtenção de episódios relacionados, de acordo com
                      critérios pré-definidos, de forma a permitir fazer o match entre os episódios.
    
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do médico cirurgião que está a aceder à grelha
                            I_EPISODE - ID do episódio
                   SAIDA:   O_CURR- Array de dados do episódio actual
                            O_PROF_NICK_NAME- Alcunha do profissional
                            O_ICON - Nome do icon de selecção
                            O_ERROR - erro
    
      CRIAÇÃO: RB 2007/01/15
      NOTAS: Se o episódio actual não for temporário, esta função não vai devolver qualquer registo, já
               que para o match, o episódio actual terá que ser sempre o temporário
    *********************************************************************************/

    FUNCTION get_match_episodes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_name        IN patient.name%TYPE,
        i_gender      IN patient.gender%TYPE,
        i_dt_birth    IN VARCHAR2,
        i_num_hplan   IN pat_health_plan.num_health_plan%TYPE,
        i_desc_interv IN VARCHAR2,
        i_dt_surg     IN VARCHAR2,
        o_epis        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função devolve um array com os dados do episódio actual que serão utilizados para a
                    obtenção de episódios relacionados, de acordo com critérios pré-definidos, de forma a permitir fazer
                    o match entre os episódios.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_PROF - ID do médico cirurgião que está a aceder à grelha
                            I_EPISODE_TEMP - ID do episódio
                    I_NAME - Nome do doente
                    I_GENDER - Sexo do doente
                    I_DT_BIRTH - Data de nascimento do doente
                    I_NUM_HPLAN - Número de cartão de utente (número do SNS)
                    I_DESC_INTERV  - Descrição dos processos cirúrgicos
                    I_DT_SURG - Data da cirurgia
                   SAIDA:   O_EPIS - Array de dados de todos os episódios relacionados
                            O_ERROR - erro
    
      CRIAÇÃO: RB 2007/01/15
      NOTAS:
    *********************************************************************************/

    FUNCTION get_match_inp_episodes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_name       IN patient.name%TYPE,
        i_gender     IN patient.gender%TYPE,
        i_dt_birth   IN VARCHAR2,
        i_num_hplan  IN pat_health_plan.num_health_plan%TYPE,
        i_department IN NUMBER,
        i_dt_begin   IN VARCHAR2,
        o_epis       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
           OBJECTIVO:  Usada no INPATIENT: Esta função devolve um array com os dados do episódio actual que serão utilizados para a
                        obtenção de episódios relacionados, de acordo com critérios pré-definidos, de forma a permitir fazer
                        o match entre os episódios.
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                                 I_EPISODE - ID do episódio
                                 I_NAME - Nome do doente
                                 I_GENDER - Sexo do doente
                                 I_DT_BIRTH - Data de nascimento do doente
                                 I_NUM_HPLAN - Número de cartão de utente (número do SNS)
                                 I_DEPARTMENT  - ID do serviço
                                 I_DT_BEGIN - Data de admissao
                       SAIDA:   O_EPIS - Array de dados de todos os episódios relacionados
                                O_ERROR - erro
    
          CRIAÇÃO: jose silva 2007/03/26
          NOTAS:
    *********************************************************************************/

    FUNCTION get_match_active_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_active  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função devolve um array com os dados dos episódios activos para a instituição/tipo de episódio
                    que serão utilizados de forma a permitir fazer o match entre os episódios.
    
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_PROF - ID do médico cirurgião que está a aceder à grelha
                            I_EPISODE_TEMP - ID do episódio
                   SAIDA:   O_ACTIVE - Array de dados de todos os episódios activos
                            O_ERROR - erro
    
      CRIAÇÃO: RB 2007/01/15
      NOTAS:
    *********************************************************************************/

    FUNCTION get_match_dpt_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_active  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função devolve um array com os dados dos episódios activos e do mesmo serviço para a instituição/tipo de episódio
                    que serão utilizados de forma a permitir fazer o match entre os episódios.
    
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                             I_EPISODE_TEMP - ID do episódio
                   SAIDA:    O_ACTIVE - Array de dados de todos os episódios activos
                             O_ERROR - erro
    *********************************************************************************/

    FUNCTION get_match_search_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_search          OUT pk_types.cursor_type,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função devolve um array com os dados do episódios ACTIVOS obtidos através dos critérios
                    de pesquisa seleccionados (por instituição e tipo de episódio).
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_PROF - ID do médico cirurgião que está a aceder à grelha
                            I_EPISODE_TEMP - ID do episódio
                    I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
                    I_CRIT_VAL - Lista de valores dos critérios de pesquisa
                   SAIDA:   O_SEARCH - Array de dados doos episódios obtidos
                      O_FLG_SHOW - Flag que indica se deve ser mostrada a mensagem
                    O_MSG - Descrição da mensagem
                    O_MSG_TITLE - Título da mensagem
                    O_BUTTON - Código dos botões a mostrar
                    O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                            O_ERROR - erro
    
      CRIAÇÃO: RB 2007/01/16
      NOTAS:
    *********************************************************************************/

    /**
    * This function marges all the information of the two patients into i_patient.
    * It ONLY updates tables that reference PATIENT.ID_PATIENT
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp temporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_match_all_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * This function merges two episodes, and deletes the temporary one
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_episode_temp temporary episode which data will be merged out, and then deleted
    * @param i_episode definitive episode id
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_match_episodes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_match_oris
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função faz o "match" entre dois episódios relacionados para as
                      tabelas específicas do ORIS.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_PROF - ID do médico cirurgião que está a aceder à grelha
                            I_EPISODE_TEMP - ID do episódio actual (temporário)
                    I_EPISODE - ID do episódio relacionado (final)
                    I_PATIENT - ID do paciente "final"
                    I_PATIENT_TEMP - ID do paciente temporário
                    SAIDA:  O_ERROR - erro
    
      CRIAÇÃO: RB 2007/01/16
    
    *********************************************************************************/

    FUNCTION set_match_edis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função faz o "match" entre dois episódios relacionados para as
                      tabelas específicas do EDIS.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_PROF - ID do médico cirurgião que está a aceder à grelha
                            I_EPISODE_TEMP - ID do episódio actual (temporário)
                    I_EPISODE - ID do episódio relacionado (final)
                    I_PATIENT - ID do paciente "final"
                    I_PATIENT_TEMP - ID do paciente temporário
                    SAIDA:  O_ERROR - erro
    
      CRIAÇÃO: RB 2007/01/16
    
    *********************************************************************************/

    /**********************************************************************************************
    * SET_MATCH_INP                          This function make "match" between related episodes in
    *                                        INPATIENT specific tables
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param i_patient_temp                  Temporary patient
    * @param i_patient                       Patient identifier 
    * @param i_transaction_id                remote transaction identifier
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Rui Batista
    * @version                               0.1
    * @since                                 2007/01/16
    *
    * @author                                Emilia Taborda
    * @version                               0.2
    * @since                                 2007/02/03
    **********************************************************************************************/
    FUNCTION set_match_inp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode_temp   IN episode.id_episode%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_patient_temp   IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_match_core
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Esta função faz o "match" entre dois episódios relacionados para as
                      tabelas específicas do CORE.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_PROF - ID do médico cirurgião que está a aceder à grelha
                            I_EPISODE_TEMP - ID do episódio actual (temporário)
                    I_EPISODE - ID do episódio relacionado (final)
                    I_PATIENT - ID do paciente "final"
                    I_PATIENT_TEMP - ID do paciente temporário
                    SAIDA:  O_ERROR - erro
    
      CRIAÇÃO: RB 2007/01/16
    
    *********************************************************************************/

    FUNCTION set_match_grid_task
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Esta função traz da tabela CRITERIA o resultado do query CRIT_MCHOICE_SELECT
    *
    * @param id_criteria   id da tabela criteria
    * @param i_lang        ID do idioma
    *
    * @return              TRUE/FALSE
    * @o_crit_mchoice      cursor com os valores da criteria
    *
    * @author              Odete Monteiro
    * @version             1.0
    * @since               2007/06/18
       ********************************************************************************************/
    FUNCTION get_crit_mchoice_select
    (
        i_criteria     IN criteria.id_criteria%TYPE,
        i_lang         IN language.id_language%TYPE,
        o_crit_mchoice OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /*********************************************************************************/
    FUNCTION get_match_search_pat_inst
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_search          OUT pk_types.cursor_type,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
     OBJECTIVO:  Esta função devolve um array com os dados dos episódios inactivos e do mesmo serviço para a instituição/tipo de episódio
                  que serão utilizados de forma a permitir fazer o match entre os pacientes.
    
     PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                  I_PROF - ID do médico cirurgião que está a aceder à grelha
                          I_EPISODE_TEMP - ID do episódio
                  I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
                  I_CRIT_VAL - Lista de valores dos critérios de pesquisa
                 SAIDA:   O_SEARCH - Array de dados doos episódios obtidos
                    O_FLG_SHOW - Flag que indica se deve ser mostrada a mensagem
                  O_MSG - Descrição da mensagem
                  O_MSG_TITLE - Título da mensagem
                  O_BUTTON - Código dos botões a mostrar
                  O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                          O_ERROR - erro
    
    CRIAÇÃO: TCO 19/06/2007
    NOTAS:
     ********************************************************************************************/

    FUNCTION get_match_currepis_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_curr    OUT pk_types.cursor_type,
        o_icon    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /***************   ***************************************************************
           OBJECTIVO:  Esta função devolve um array com os dados do episódio actual (verdadeiro ou temporario)
                          que serão utilizados para a obtenção de episódios relacionados, de acordo com
                    critérios pré-definidos, de forma a permitir fazer o match entre os episódios.
    
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do médico cirurgião que está a aceder à grelha
                                I_EPISODE - ID do episódio
                       SAIDA:   O_CURR- Array de dados do episódio actual
                                  O_ICON - Nome do icon de selecção
                                O_ERROR - erro
    CRIAÇÃO: TCO 2007/06/27*****/

    /******************************************************************************
    * This function does a dry run on set_match_episodes, to
    * see if the two episodes will match ok. Failure means a Pl/SQL bug
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_episode_temp temporary episode which data will be merged out, and then deleted
    * @param i_episode definitive episode id
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION test_match_episodes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function changes the id_patient of the i_old_episode
    * and associated visit to the i_new_patient
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_new_patient new patient id
    * @param i_old_episode id of episode for which the associated patient will change
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_episode_new_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_new_patient IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    g_active    CONSTANT VARCHAR2(1) := 'A';
    g_cancel    CONSTANT VARCHAR2(1) := 'C';
    g_inactive  CONSTANT VARCHAR2(1) := 'I';
    g_default_y CONSTANT VARCHAR2(1) := 'Y';
    f_flg_def_n CONSTANT VARCHAR2(1) := 'N';

    flg_type_sns      CONSTANT health_plan.flg_type%TYPE := 'S';
    flg_instit_type_h CONSTANT health_plan.flg_instit_type%TYPE := 'H';
    g_soft_oris       CONSTANT software.id_software%TYPE := 2;
    g_soft_edis       CONSTANT software.id_software%TYPE := 8;
    g_soft_inp        CONSTANT software.id_software%TYPE := 11;

    g_hand_icon CONSTANT VARCHAR2(40) := 'HandSelectedIcon';

    --Tipos de episódio
    g_flg_unknown_temp CONSTANT epis_info.flg_unknown%TYPE := 'Y';
    g_flg_unknown_def  CONSTANT epis_info.flg_unknown%TYPE := 'N';

    g_no_triage            CONSTANT VARCHAR2(200) := '0x787864';
    g_no_triage_color_text CONSTANT VARCHAR2(200) := '0xFFFFFF';

    g_software_oris CONSTANT software.id_software%TYPE := 2;
    g_software_edis CONSTANT software.id_software%TYPE := 8;
    g_software_inp software.id_software%TYPE := 8;
    g_software_ubu software.id_software%TYPE := 29; --om 13/07/2007

    g_epis_type_ubu epis_type.id_epis_type%TYPE := 9; --tco 21/06/2007

    g_epis_inactive CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_pending  CONSTANT episode.flg_status%TYPE := 'P';

    -- HÍDRICOS
    g_epis_hidric_r epis_hidrics.flg_status%TYPE;
    g_epis_hidric_e epis_hidrics.flg_status%TYPE;
    g_epis_hidric_f epis_hidrics.flg_status%TYPE;
    g_epis_hidric_c epis_hidrics.flg_status%TYPE;
    g_epis_hidric_i epis_hidrics.flg_status%TYPE;
    -- POSICIONAMENTOS
    g_epis_posit_r epis_positioning.flg_status%TYPE;
    g_epis_posit_e epis_positioning.flg_status%TYPE;
    g_epis_posit_f epis_positioning.flg_status%TYPE;
    g_epis_posit_c epis_positioning.flg_status%TYPE;
    g_epis_posit_i epis_positioning.flg_status%TYPE;
    -- DIET
    g_diet_status_r epis_diet.flg_status%TYPE;
    g_diet_status_i epis_diet.flg_status%TYPE;
    g_diet_status_c epis_diet.flg_status%TYPE;
    --
    g_catg_prof_doctor CONSTANT category.flg_type%TYPE := 'D';
    g_catg_prof_nurse  CONSTANT category.flg_type%TYPE := 'N';

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';
    --Tipos de Episódio
    g_episode_flg_ehr_n CONSTANT episode.flg_ehr%TYPE := 'N';
    g_epis_type_oris    CONSTANT epis_type.id_epis_type%TYPE := 4;
    --Exception
    g_exception EXCEPTION;
END pk_match;
/
