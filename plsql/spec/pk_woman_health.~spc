/*-- Last Change Revision: $Rev: 2029061 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_woman_health IS

    /************************************************************************************************************
    * Gets a formatted value to be used in the periodic observation grid
    *
    * @param      i_lang     language
    * @param      i_prof     profisisonal
    * @param      i_value    value to be formatted
    *
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     José Silva
    * @version    0.1
    * @since      2010/09/10
    ***********************************************************************************************************/
    FUNCTION get_formatted_value
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_value IN VARCHAR2
    ) RETURN VARCHAR2;

    /******************************************************************************
       OBJECTIVO:   Obter todos os events activos registados para a grávida e respectivas datas de registo
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PATIENT - ID do paciente
                             I_PROF - ID do profissional
                             I_INTERN_NAME - Intern Name do TIME_EVENT_GROUP (ex: WOMAN_HEALTH_DET)
                             I_PAT_PREGNANCY - ID da gravidez
                    Saida: O_TIME - Listar todas as datas onde se registaram os sinais vitais
                             O_SIGN_V - Listar todos os events registados no tempo de gravidez
                             O_VAL_HABIT - Valores habituais dos events
                             O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/17
      NOTA:
    *********************************************************************************/

    FUNCTION get_time_event_axis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_flg_screen    IN VARCHAR2,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO: Retorna para cada data de registo / event do episódio, os valores,
                  sendo estes visualizados numa grelha
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                I_PATIENT - ID do episódio
                                I_PROF - Trinomio do profissional
                                I_FLG_SCREEN - Ecrã - (D) Detalhe ou (G) Gráfico
                                I_INTERN_NAME - Intern Name do TIME_EVENT_GROUP
                                I_PAT_PREGNANCY - ID da gravidez
                    Saida: O_VAL_VS - Array para cada event / tempo de leitura, os respectivos valores
                     O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2006/12/12
      NOTA:
    *********************************************************************************/

    FUNCTION get_time_event_all
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_flg_screen    IN VARCHAR2,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter todas as gravidezes da paciente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do Paciente
                            I_PROF - ID do profissional
                    Saida: O_PREG - Listagem das gravidezes
                     O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/29
      NOTA:
    *********************************************************************************/

    FUNCTION get_pat_pregnancy_type
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter os tipos de gravidezes (em curso ou anterior)
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do Paciente
                            I_PROF - ID do profissional
                    Saida: O_PREG - Listagem das gravidezes
                            O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/30
      NOTA:
    *********************************************************************************/

    FUNCTION get_pat_pregnancy_time
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter os tipos de gravidezes (em curso ou anterior)
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do Paciente
                            I_PROF - ID do profissional
                    Saida: O_PREG - Listagem das gravidezes
                            O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/30
      NOTA:
    *********************************************************************************/

    FUNCTION get_pat_pregnancy_abbort
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Criar nova gravidez ou actualizar gravidez existente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do paciente
                            I_DT_LAST_MENSTRUATION - Data da Última menstruação
                            I_DT_CHILDBIRTH - Data do Parto
                            I_N_PREGNANCY - Número da gravidez
                            I_FLG_CHILDBIRTH_TYPE - Tipo da gravidez (ectoccica ou cesariana)
                            I_N_CHILDREN - Nº de nados-vivos
                            I_FLG_ABBORT - Se é aborto ou gravidez ectópica
                            I_FLG_ACTIVE - Se é gravidez anterior ou em curso
                            I_PROF - Profissional
                            I_ID_EPISODE - ID do episódio
                    Saida:  O_MSG - Mensagem a apresentar
                            O_MSG_TITLE - Título da ensagem a apresentar
                            O_FLG_SHOW - Mostrar ou não ao utilizador
                            O_BUTTON - Tipo de botão a apresentar
                            O_ERROR - erro
    
      CRIAÇÃO: RdSN 2007/01/30
      NOTAS:
    *********************************************************************************/

    FUNCTION set_pat_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_patient              patient.id_patient%TYPE,
        i_pat_pregnancy        pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_last_menstruation pat_pregnancy.dt_last_menstruation%TYPE,
        i_dt_childbirth        DATE,
        i_n_pregnancy          pat_pregnancy.n_pregnancy%TYPE,
        i_flg_childbirth_type  VARCHAR2, --pat_pregnancy.flg_childbirth_type%TYPE,
        i_n_children           pat_pregnancy.n_children%TYPE,
        i_flg_abbort           VARCHAR2, --pat_pregnancy.flg_abbort%TYPE,
        i_flg_active           IN VARCHAR2, --PAT_PREGNANCY.FLG_ACTIVE%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_cdr_call             IN cdr_event.id_cdr_call%TYPE, --ALERT-175003
        o_msg                  OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Verifica se existe alguma gravidez activa
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do Paciente
                            I_PROF - ID do profissional
                    Saida: O_PREG - Listagem das gravidezes
                     O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/30
      NOTA:
    *********************************************************************************/

    FUNCTION check_current_preg
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter os tipos de novos membros da familia
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do Paciente
                            I_PROF - ID do profissional
                    Saida: O_PREG - Listagem das gravidezes
                     O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/30
      NOTAS: Se for homem, não tem a opção de Novo Recém-nascido
    *********************************************************************************/

    FUNCTION get_pat_new_family_member
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter os dados da família para o feto/recem-nascido
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PATIENT - ID do Paciente
                        I_PROF - ID do profissional
                    Saida: O_PREG - Listagem das gravidezes
                     O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/30
      NOTAS: !!!!! NÃO É USADA (PARA JA!) !!!!!
    *********************************************************************************/

    FUNCTION get_newborn_fam_data
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Actualizar dados do paciente no que diz respeito a pertence à família da mãe
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PATIENT - ID do Paciente
                        I_NEW_PATIENT - ID do novo Paciente naquela familia
                        I_PROF - ID do profissional
                    Saida: O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/01/31
      NOTAS:
    *********************************************************************************/

    FUNCTION set_pat_family
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_new_patient IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Alteração dos dados da gravidez no deepnav de RH
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PATIENT - ID do Paciente
                        I_PAT_PREGNANCY - ID da gravidez
                        I_BLOOD_TYPE_MOTHER - Sangue da mãe (Rhesus + Type)
                        I_BLOOD_TYPE_FATHER - Sangue da mãe (Rhesus + Type)
                        I_FLG_ANTIGL_AFT_CHB - Antiglobulina após os partos RH+
                        I_FLG_ANTIGL_AFT_ABB - Antiglobulina após os abortos
                        I_FLG_ANTIGL_NEED - Antiglobulina
                        I_PROF - ID do profissional
                    Saida: O_MSG - Mensagem a mostrar
                        O_MSG_TITLE - Título da mensagem a mostrar
                        O_FLG_SHOW - Y se tem mensagem a mostrar
                        O_BUTTON - Retorno para função de controle do flash
                        O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/03
      NOTAS: Pode alterar o tipo de sangue da mãe, pelo que deve lançar uma msg de aviso
    *********************************************************************************/

    FUNCTION set_pat_pregnancy_rh
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_blood_type_mother  IN VARCHAR2,
        i_blood_type_father  IN VARCHAR2,
        i_flg_antigl_aft_chb IN pat_pregnancy.flg_antigl_aft_chb%TYPE,
        i_flg_antigl_aft_abb IN pat_pregnancy.flg_antigl_aft_abb%TYPE,
        i_flg_antigl_need    IN pat_pregnancy.flg_antigl_need%TYPE,
        i_flg_confirm        IN VARCHAR2,
        i_prof               IN profissional,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter dados da gravidez para o ecrã de detalhe
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do Paciente
                            I_PAT_PREGNANCY - ID da gravidez
                            I_PROF - ID do profissional
                    Saida:  O_PREG - Cursor com info da grávida
                            O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/03
      NOTAS:
    *********************************************************************************/

    FUNCTION get_pat_pregnancy_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        o_preg          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter tempo de gestação
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_DT_LAST_MENST - Data da última menstruação
                            I_DT_CORRECT - Data corrigida de concepção
                            I_PROF - ID do profissional
                    Saida:  O_PREG - Cursor com info da grávida
                            O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/04
      NOTAS:
    *********************************************************************************/

    FUNCTION get_pregnancy_timeframe
    (
        i_lang          IN language.id_language%TYPE,
        i_dt_last_menst IN pat_pregnancy.dt_last_menstruation%TYPE,
        i_dt_correct    IN pat_pregnancy.dt_pdel_correct%TYPE,
        i_prof          IN profissional,
        o_preg          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO: Obter os eventos parametrizados e forma de inserção no UI
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional
                             I_INTERN_NAME - Intern name do TIME_EVENT_GROUP
                             I_PATIENT - ID do paciente
                             I_PAT_PREGNANCY - ID da gravidez
                    Saida:   O_SIGN_V - Detalhe dos eventos
                             O_PREG - Dados necessários da gravidez (para o deepnav de RH)
                             O_VACC_STATUS - Dados de eventos vacinas (status)
                             O_VACC_ADMIN - Dados de eventos vacinas (doses e administração)
                             O_VAL_HABIT - Valores habituais das análises e sinais vitais
                             O_ERROR - erro
    
       CRIAÇÃO: RdSN 2007/02/03
    
    *********************************************************************************/

    FUNCTION get_vs_header
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_sign_v        OUT pk_types.cursor_type,
        o_preg          OUT pk_types.cursor_type,
        o_vacc_status   OUT pk_types.cursor_type,
        o_vacc_admin    OUT pk_types.cursor_type,
        o_vacc_dose     OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter os valores para vários multichoices
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do Paciente
                            I_PROF - ID do profissional
                    Saida: O_PREG - Listagem das gravidezes
                            O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/06
      NOTA:
    *********************************************************************************/

    FUNCTION get_pregnancy_data_domain
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        i_intern_name IN VARCHAR2,
        o_preg        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       NÃO USADA!
    
       CRIAÇÃO: RdSN 2007/02/03
    
    *********************************************************************************/

    FUNCTION set_analysis_most_freq
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_analysis_req_par   IN table_number,
        i_parameter_analysis IN table_number,
        i_prof               IN profissional,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Gravação de administração de vacinas
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PATIENT - ID do Paciente
                        I_VACCINE - array de vacinas
                        I_VACCINE_DET - array de ID de detalhe
                        I_N_DOSE - array de nº de doses
                        I_DT_ADMIN - array de datas de administração
                        I_PROF - ID do profissional
                    Saida: O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/10
      NOTAS:
    *********************************************************************************/

    FUNCTION set_vaccine_dose_admin
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_vaccine     IN table_varchar,
        i_vaccine_det IN table_varchar,
        i_n_dose      IN table_number,
        i_dt_admin    IN table_varchar,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Gravação da alteração do estado das vacinas
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PATIENT - ID do Paciente
                        I_FLG_STATUS - array de FLG_STATUS da vacina
                        I_VACCINE - array de vacinas
                        I_VACCINE_DET - array de ID de detalhe
                        I_PROF - ID do profissional
                    Saida: O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/03/05
      NOTAS:
    *********************************************************************************/

    FUNCTION set_vaccine_status
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_flg_status  IN table_varchar,
        i_vaccine     IN table_varchar,
        i_vaccine_det IN table_varchar,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Criação de intercorrência (episódio da grávida)
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_EPISODE - ID do Episódio
                        I_PAT_PREGNANCY - ID da gravidez
                        I_PROF - ID do profissional
                    Saida: O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/11
      NOTAS:
    *********************************************************************************/

    FUNCTION create_epis_pregnancy
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Actualiza os registos habituais
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PATIENT - ID do Paciente
                        I_ID_GROUP - Array com ID_VITAL_SIGN / ID_ANALYSIS
                        I_VALUE - Array com os valores
                        I_ID_UNIT_MEAS - Array com as unidades de medida
                        I_PAT_PREGNANCY - ID da gravidez
                        I_PROF - ID do profissional
                    Saida: O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/14
      NOTAS:
    *********************************************************************************/

    FUNCTION set_event_most_freq
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_id_group      IN table_number,
        i_flg_group     IN table_varchar,
        i_value         IN table_varchar,
        i_id_unit_meas  IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_event_most_freq
    (
        i_lang            IN language.id_language%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_group        IN table_number,
        i_flg_group       IN table_varchar,
        i_value           IN table_varchar,
        i_id_unit_meas    IN table_number,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_pregn_fetus IN pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Cancelar gravidez existente
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                            I_PATIENT - ID do paciente
                            I_PAT_PREGNANCY - ID da gravidez
                            I_PROF - Profissional
                            I_CONFIRM - Flag de confirmação do cancelamento da gravidez
                    Saida:  O_MSG - Mensagem a mostrar ao utilizador
                            O_MSG_TITLE - Titulo da mensagem a mostrar ao utilizador
                            O_FLG_SHOW - Flg a assinalar se deverá ser mostrada a msg
                            O_BUTTON - Tipo de botão a apresentar ao utilizador
                            O_ERROR - erro
    
      CRIAÇÃO: RdSN 2007/02/15
      NOTAS:
    *********************************************************************************/

    FUNCTION cancel_pat_pregnancy
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       patient.id_patient%TYPE,
        i_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        i_flg_confirm   IN VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Função para cálculo da idade do pai a partir da sua data de nascimento
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_DT_BIRTH - Data de nascimento
                        I_PROF - ID do profissional
                    Saida: O_ERROR - Erro
    
      CRIAÇÃO: RdSN 2007/02/23
      NOTAS:
    *********************************************************************************/

    FUNCTION get_father_age
    (
        i_lang     IN language.id_language%TYPE,
        i_dt_birth IN patient.dt_birth%TYPE,
        i_prof     IN profissional,
        o_age      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter lista de descritivos de uma análise cuja leitura não é numérica
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_ANALYSIS - ID da Análise cujos descritivos se pretende
                             I_ANALYSIS_PARAM - ID do Parametro da Análise cujos descritivos se pretende
                    Saida:   O_ANALYSIS - descritivos
                             O_ERROR - erro
    
      CRIAÇÃO: RdSN 2007/02/26
    *********************************************************************************/

    FUNCTION get_analysis_desc_list
    (
        i_lang           IN language.id_language%TYPE,
        i_analysis       IN analysis_desc.id_analysis%TYPE,
        i_analysis_param IN analysis_desc.id_analysis_parameter%TYPE DEFAULT NULL,
        o_analysis       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter lista de descritivos de uma vacina cuja leitura não é numérica
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_VACCINE - ID da Vacina cujos descritivos se pretende
              Saida:   O_VACCINE - descritivos
                 O_ERROR - erro
    
      CRIAÇÃO: RdSN 2007/02/26
    *********************************************************************************/

    FUNCTION get_vaccine_desc_list
    (
        i_lang    IN language.id_language%TYPE,
        i_vaccine IN analysis_desc.id_analysis%TYPE,
        o_vaccine OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Verifica se pode criar gravidezes para aquele paciente ( se não for homem e menor de 12 anos )
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PATIENT - ID do paciente
              Saida:   O_AVAIL - permissão para criar gravidezes
                 O_ERROR - erro
    
      CRIAÇÃO: RdSN 2007/03/14
      NOTAS:
    *********************************************************************************/

    FUNCTION get_pat_preg_avail
    (
        i_lang             IN language.id_language%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        o_avail            OUT VARCHAR2,
        o_dt_min           OUT VARCHAR2,
        o_id_pat_pregnancy OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_dt_preg_init     OUT VARCHAR2,
        o_dt_preg_end      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_preg_converted_time
    (
        i_lang           IN language.id_language%TYPE,
        i_weeks          IN NUMBER,
        i_dt_preg        IN DATE,
        i_dt_reg         IN DATE,
        o_weeks          OUT NUMBER,
        o_trimester      OUT NUMBER,
        o_desc_trimester OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_new_fetus_biom
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_pat_pregn_fetus      IN pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        i_id_vital_sign           IN vital_sign.id_vital_sign%TYPE,
        i_vs_value                IN pat_pregn_fetus_biom.value%TYPE,
        o_id_pat_pregn_fetus_biom OUT pat_pregn_fetus_biom.id_pat_pregn_fetus_biom%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION conv_weeks_to_trimester(i_weeks IN NUMBER) RETURN NUMBER;

    FUNCTION set_pregnancy_register
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_desc_register    IN pregnancy_register.desc_register%TYPE,
        i_flg_type         IN pregnancy_register.flg_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pregnancy_register
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type         IN pregnancy_register.flg_type%TYPE,
        o_pregn_register   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_time_event_det
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_reg   IN NUMBER,
        i_flg_type IN VARCHAR2,
        o_val_det  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_woman_health_non_doc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_values          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_pregnancy_new
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_abort_ectopic_label
    (
        i_lang                  IN language.id_language%TYPE,
        i_flg_abbort            IN VARCHAR2, --pat_pregnancy.flg_abbort%TYPE,
        i_flg_abortion_type     IN VARCHAR2, --pat_pregnancy.flg_abortion_type%TYPE,
        i_gestation_time        IN pat_pregnancy.num_gest_weeks%TYPE,
        i_flg_ectopic_pregnancy IN VARCHAR2, --pat_pregnancy.flg_ectopic_pregnancy%TYPE,
        o_l_flg_abbort_desc     OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_abort_ectopic_str
    (
        i_lang                  IN language.id_language%TYPE,
        i_flg_abbort            IN VARCHAR2, --pat_pregnancy.flg_abbort%TYPE,
        i_flg_abortion_type     IN VARCHAR2, --pat_pregnancy.flg_abortion_type%TYPE,
        i_gestation_time        IN pat_pregnancy.num_gest_weeks%TYPE,
        i_flg_ectopic_pregnancy IN VARCHAR2 --pat_pregnancy.flg_ectopic_pregnancy%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pregnancy_weeks
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_pat   IN NUMBER,
        o_age   OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_time_event_axis_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_time_event_all_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_analysis_time_ev_axis_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_analysis      OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_analysis_time_ev_all_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_val_analysis  OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_woman_health_analysis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis_time OUT pk_types.cursor_type,
        o_analysis_par  OUT pk_types.cursor_type,
        o_analysis_val  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_woman_health_vaccines
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_vaccines_time OUT pk_types.cursor_type,
        o_vaccines_par  OUT pk_types.cursor_type,
        o_vaccines_val  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_woman_health_vital_signs
    (
        i_lang             IN language.id_language%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_intern_name      IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_vital_signs_time OUT pk_types.cursor_type,
        o_vital_signs_par  OUT pk_types.cursor_type,
        o_vital_signs_val  OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_woman_health_immunology
    (
        i_lang            IN language.id_language%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_prof            IN profissional,
        i_intern_name     IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_immunology_time OUT pk_types.cursor_type,
        o_immunology_par  OUT pk_types.cursor_type,
        o_immunology_val  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_woman_health_rh
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_rh_time       OUT pk_types.cursor_type,
        o_rh_par        OUT pk_types.cursor_type,
        o_rh_val        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_woman_health_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_summary_time  OUT pk_types.cursor_type,
        o_summary_par   OUT pk_types.cursor_type,
        o_summary_val   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_analysis_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis      OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_vaccines_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_vaccines      OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_immunology_create
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_intern_name        IN time_event_group.intern_name%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis           OUT pk_types.cursor_type,
        o_analysis_val_habit OUT pk_types.cursor_type,
        o_vaccines           OUT pk_types.cursor_type,
        o_vaccines_val_habit OUT pk_types.cursor_type,
        o_vaccines_status    OUT pk_types.cursor_type,
        o_vaccines_admin     OUT pk_types.cursor_type,
        o_vaccines_dose      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rh_create
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_intern_name        IN time_event_group.intern_name%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis           OUT pk_types.cursor_type,
        o_analysis_val_habit OUT pk_types.cursor_type,
        o_preg_info          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_usual_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_intern_name    IN time_event_group.intern_name%TYPE,
        i_patient        IN analysis_result.id_patient%TYPE,
        i_pat_pregnancy  IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_event       IN event.id_group%TYPE,
        o_usual_val      OUT pk_types.cursor_type,
        o_usual_val_str  OUT VARCHAR2,
        o_usual_icon_str OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_usual_values_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN analysis_result.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_event      IN event.id_group%TYPE,
        i_is_icon       IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION set_analysis_create
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_pat_pregnancy          IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_par_analysis           IN table_table_number, -- analysisId|resultId
        i_results                IN table_varchar,
        i_analysis_desc          IN table_number,
        i_results_habit          IN table_varchar,
        i_analysis_req_det_id    IN table_number,
        i_unit_measure           IN table_number,
        i_date_str               IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the minimum date of service
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient ID
    * @param i_pat_pregnancy          pregnancy ID
    * @param o_dt_reg                 minimum date of service
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        2.5
    * @since                          2010/10/15
    **********************************************************************************************/
    FUNCTION get_min_dt_reg
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_dt_reg        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Verifies if woman is pregnant
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient ID
    * @param o_flg_pregnant           'Y' is pregnant; otherwise 'N'
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.1.0.1
    * @since                          2011/05/10
    **********************************************************************************************/
    FUNCTION is_woman_pregnant
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_flg_pregnant OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**######################################################
      GLOBAL DEFINITIONS
    ######################################################**/

    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    g_exception EXCEPTION;
    --
    g_vs_rel_conc    vital_sign_relation.relation_domain%TYPE;
    g_vs_rel_sum     vital_sign_relation.relation_domain%TYPE;
    g_vs_rel_man     vital_sign_relation.relation_domain%TYPE;
    g_vs_bio         vital_sign.flg_vs%TYPE;
    g_vs_read_active vital_sign_read.flg_state%TYPE;
    g_vs_read_cancel vital_sign_read.flg_state%TYPE;
    g_vs_avail       vital_sign.flg_available%TYPE;
    g_vs_show        vital_sign.flg_show%TYPE;
    g_vs_not_show    vital_sign.flg_show%TYPE;
    g_vs_char        vital_sign.flg_fill_type%TYPE;
    g_vs_pain        vital_sign.id_vital_sign%TYPE;
    g_vs_fill_char   vital_sign.flg_fill_type%TYPE;
    --
    g_available vital_sign_notes.flg_available%TYPE;
    --
    g_active epis_documentation.flg_status%TYPE;

    -- for the pregnancy window calculus
    g_weeks_gest        CONSTANT NUMBER := 44;
    g_weeks_gest_normal CONSTANT NUMBER := 40;
    g_days_in_week      CONSTANT NUMBER := 7;

    g_type_graph VARCHAR2(1);
    g_type_table VARCHAR2(1);

    g_epis_bartchart_out CONSTANT epis_documentation.flg_status%TYPE := 'O';
    g_child_status_alive CONSTANT epis_doc_delivery.flg_child_status%TYPE := 'A';
    g_child_status_dead  CONSTANT epis_doc_delivery.flg_child_status%TYPE := 'D';

    --saude materna
    g_type_woman_health CONSTANT VARCHAR2(1) := 'M';

    --separador
    g_sep CONSTANT VARCHAR2(1) := '|';

    g_dt_format CONSTANT VARCHAR2(50) := 'yyyymmddhh24miss TZR';

    --Log
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END;
/
