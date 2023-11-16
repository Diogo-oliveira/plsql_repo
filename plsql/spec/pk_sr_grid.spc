/*-- Last Change Revision: $Rev: 2028980 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:06 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_grid IS

    FUNCTION get_daily_schedule
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grid_pat_in_planning
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grid_aux_all_patients
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter a o agendamento do dia do Bloco Operatório, para o Auxiliar. Devolve todas as
                          intervenções do dia do bloco com workflows activos.
    
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_DT - Data. se for nula, considera a data de sistema
                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                           SAIDA:   O_GRID - array de agendamentos
                              O_ROOM - Array de estados possíveis das salas
                                     O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/07
      NOTAS:
    *********************************************************************************/

    FUNCTION get_room_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_room    IN room.id_room%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt      IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_grid_surg_v1
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter o agendamento do dia do Bloco Operatório, para o médico cirurgião. Devolve todas as
                          intervenções do dia a que o profissional esteja agendado - VISTA 1.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_DT - Data. se for nula, considera a data de sistema
                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                                              I_TYPE - Indica se se pretende ver apenas os agendamentos aos quais o profissional
                                                está alocado ou todos os agendamentos. Valores possíveis:
                                                           A - Todos os agendamentos
                                                                P - Agendamentos do profissional
                           SAIDA:   O_GRID - array de agendamentos
                              O_ROOM - Array de estados possíveis das salas
                                        O_PAT - Array de estados possíveis do paciente
                                     O_ERROR - erro
    
      CRIAÇÃO: RB 2006/09/12
      NOTAS:
    *********************************************************************************/

    FUNCTION get_grid_surg_v2
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter o agendamento do dia do Bloco Operatório, para o médico cirurgião. Devolve todas as
                          intervenções do dia a que o profissional esteja agendado - VISTA 2.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_DT - Data. se for nula, considera a data de sistema
                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                                              I_TYPE - Indica se se pretende ver apenas os agendamentos aos quais o profissional
                                                está alocado ou todos os agendamentos. Valores possíveis:
                                                           A - Todos os agendamentos
                                                                P - Agendamentos do profissional
                           SAIDA:   O_GRID - array de agendamentos
                              O_ROOM - Array de estados possíveis das salas
                                        O_PAT - Array de estados possíveis do paciente
                                     O_ERROR - erro
    
      CRIAÇÃO: RB 2006/09/12
      NOTAS:
    *********************************************************************************/

    FUNCTION get_grid_prof_team_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_prof    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter a informação relativa à equipa de profissionais agendados para um episódio
           de cirurgia
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_EPISODE - Data. se for nula, considera a data de sistema
                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                           SAIDA:   O_PROF - array de profissionais agendados para um episódio
                                     O_ERROR - erro
    
      CRIAÇÃO: RB 2006/09/12
      NOTAS:
    *********************************************************************************/

    FUNCTION get_search_grid_surg_actv_v1
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
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados ,
                    para pessoal clínico (médicos e enfermeiros) - VISTA 1
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
            I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
            I_CRIT_VAL - Lista de valores dos critérios de pesquisa
         I_INSTIT - Instituição
         I_EPIS_TYPE - Tipo de consulta
         I_DT - Data a pesquisar. Se for null assume a data de sistema
            I_PROF - ID do profissional q regista
         I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                 como é retornada em PK_LOGIN.GET_PROF_PREF
              Saida:   O_PAT - doentes activos
              O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                             O_WAIT_ICON - Nome do icone a mostrar quando não há data prevista para a realização da
                                cirurgia
         O_ERROR - erro
    
      CRIAÇÃO: RB 2006/08/23
      NOTAS:
    *********************************************************************************/

    FUNCTION get_search_grid_surg_actv_v2
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
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados ,
                    para pessoal clínico (médicos e enfermeiros) - VISTA 2
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
            I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
            I_CRIT_VAL - Lista de valores dos critérios de pesquisa
         I_INSTIT - Instituição
         I_EPIS_TYPE - Tipo de consulta
         I_DT - Data a pesquisar. Se for null assume a data de sistema
            I_PROF - ID do profissional q regista
         I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                 como é retornada em PK_LOGIN.GET_PROF_PREF
              Saida:   O_PAT - doentes activos
              O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                             O_WAIT_ICON - Nome do icone a mostrar quando não há data prevista para a realização da
                                cirurgia
         O_ERROR - erro
    
      CRIAÇÃO: RB 2006/08/23
      NOTAS:
    *********************************************************************************/

    FUNCTION get_search_grid_surg_inactv_v1
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
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes INACTIVOS, de acordo com os critérios seleccionados ,
                    para pessoal clínico (médicos e enfermeiros) - VISTA 1
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
            I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
            I_CRIT_VAL - Lista de valores dos critérios de pesquisa
         I_INSTIT - Instituição
         I_EPIS_TYPE - Tipo de consulta
         I_DT - Data a pesquisar. Se for null assume a data de sistema
            I_PROF - ID do profissional q regista
         I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                 como é retornada em PK_LOGIN.GET_PROF_PREF
              Saida:   O_PAT - doentes activos
              O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                             O_WAIT_ICON - Nome do icone a mostrar quando não há data prevista para a realização da
                                cirurgia
         O_ERROR - erro
    
      CRIAÇÃO: RB 2006/08/23
      NOTAS:
    *********************************************************************************/

    FUNCTION get_search_grid_surg_inactv_v2
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
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes INACTIVOS, de acordo com os critérios seleccionados ,
                    para pessoal clínico (médicos e enfermeiros) - VISTA 2
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
            I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
            I_CRIT_VAL - Lista de valores dos critérios de pesquisa
         I_INSTIT - Instituição
         I_EPIS_TYPE - Tipo de consulta
         I_DT - Data a pesquisar. Se for null assume a data de sistema
            I_PROF - ID do profissional q regista
         I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                 como é retornada em PK_LOGIN.GET_PROF_PREF
              Saida:   O_PAT - doentes activos
              O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                             O_WAIT_ICON - Nome do icone a mostrar quando não há data prevista para a realização da
                                cirurgia
         O_ERROR - erro
    
      CRIAÇÃO: RB 2006/08/23
      NOTAS:
    *********************************************************************************/

    FUNCTION set_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status_new IN VARCHAR2,
        i_flg_status_old IN VARCHAR2,
        i_test           IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status_new IN VARCHAR2,
        i_flg_status_old IN VARCHAR2,
        i_test           IN VARCHAR2,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN schedule_sr.notes_cancel%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*
        FUNCTION call_set_pat_status
        (
            i_lang           IN LANGUAGE.id_language%TYPE,
            i_prof           IN profissional,
            i_episode        IN episode.id_episode%TYPE,
            i_flg_status_new IN VARCHAR2,
            i_flg_status_old IN VARCHAR2,
            i_test           IN VARCHAR2,
            i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
            i_cancel_notes   IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
            i_transaction_id IN VARCHAR2,
            o_flg_show       OUT VARCHAR2,
            o_msg_title      OUT VARCHAR2,
            o_msg_text       OUT VARCHAR2,
            o_button         OUT VARCHAR2,
            o_error          OUT t_error_out
        ) RETURN BOOLEAN;
    */

    /********************************************************************************************
    * Guarda o estado de um paciente. O estado do paciente é guardado na tabela de histórico de estados,
    * de forma a permitir a consulta posterior do tempo em que um paciente esteve em cada estado.
    * O seu estado actual é também guardado na tabela SR_SURGERY_RECORD.
    *
    * @param i_lang               Id do idioma
    * @param i_prof               Id do profissional, instituição e software
    * @param i_episode            Id do episódio
    * @param i_flg_status_new     Estado actual do paciente
    * @param i_flg_status_old     Anterior estado do paciente
    * @param i_test               Indica se deve validar o o estado do paciente
    * @param i_transaction_id     New Scheduler transaction ID
    *
    * @param o_flg_show           Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title          Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text           Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button             Botões a mostrar: N - não, R - lido, C - confirmado
    * @param o_error              Mensagem de erro
    *
    * @return                     TRUE/FALSE
    *
    * @author                     Rui Batista
    * @since                      2006/06/09
    *
    * @alter                      José Brito
    * @since                      2008/08/29
    *
    * @alter                      José Antunes
    * @since                      2008/11/05
       ********************************************************************************************/
    FUNCTION call_set_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status_new IN VARCHAR2,
        i_flg_status_old IN VARCHAR2,
        i_test           IN VARCHAR2,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes   IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Guarda o estado de um paciente
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                       I_PROF - ID do profissional, software e instituição
                                              I_EPISODE - ID do episódio
                                              I_FLG_STATUS_NEW - Estado actual do paciente
                                              I_FLG_STATUS_OLD - Anterior estado do paciente
                                              I_TEST - Indica se deve validar o o estado do paciente
                           SAIDA:   O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N)
          O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                                   O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/09
      NOTAS:   O estado do paciente é guardado na tabela de histórico de estados, de forma a permitir a consulta
              posterior do tempo em que um paciente esteve em cada estado. O seu estado actual é também
                    guardado na tabela SR_SURGERY_RECORD
    *********************************************************************************/

    FUNCTION set_pat_status_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_notes   IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Guarda as notas de estado de um paciente
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                     I_PROF - ID do profissional, software e instituição
                                              I_EPISODE - ID do episódio
                                              I_NOTES - Notas
                           SAIDA:   O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/09
      NOTAS:   O estado do paciente é guardado na tabela de histórico de estados, de forma a permitir a consulta
              posterior do tempo em que um paciente esteve em cada estado. O seu estado actual é também
                    guardado na tabela SR_SURGERY_RECORD
    *********************************************************************************/

    FUNCTION get_pat_status_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN VARCHAR2,
        o_status     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem a lista de estados possíveis de um paciente
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                     I_PROF - ID do profissional, software e instituição
                                              I_FLG_STATUS - Estado actual do paciente
                           SAIDA:   O_STATUS - Lista de salas
                              O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/08
      NOTAS:   O FLG_STATUS recebe o valor do estado actual do paciente de forma a que este não seja mostrado
             na lista. Assim, não é permitido actualizar o estado de um paciente para o mesmo que estava anteriormente.
    *********************************************************************************/

    FUNCTION get_pat_status_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_pat_status OUT VARCHAR2,
        o_pat_notes  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter o estado do paciente e as notas
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
              I_EPISODE - ID do episódio
                                         I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_PAT_STATUS - Estado do paciente
                              O_PAT_NOTES - Notas de estado do paciente
                                    O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/08
      NOTAS: O estado do paciente é guardado nas tabelas SR_SURGERY_RECORD (último estado) e SR_PAT_STATUS.
          Como aqui apenas queremos o último, vamos obtê-lo na SR_SURGERY_RECORD
    *********************************************************************************/

    FUNCTION get_room_status
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_room    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem a lista de salas e respectivos estados
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                      I_EPISODE - ID do episódio
                                     I_PROF - ID do profissional, software e instituição
                           SAIDA:   O_ROOM - Lista de salas
                              O_LIMPA - Label 'Limpa"
                                        O_OCUPADA - Label 'Ocupada''
                                        O_LIMPEZA - Label 'Em limpeza''
                                      O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/05
      NOTAS:
    *********************************************************************************/

    FUNCTION get_room_status_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN VARCHAR2,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem a lista de estados possíveis de uma sala
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                     I_PROF - ID do profissional, software e instituição
                                              I_FLG_STATUS - Estado actual da sala
                           SAIDA:   O_ROOM - Lista de salas
                              O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/07
      NOTAS:
    *********************************************************************************/

    FUNCTION set_room_status
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_room      IN room.id_room%TYPE,
        i_prof      IN profissional,
        i_status    IN VARCHAR2,
        i_notes     IN VARCHAR2,
        i_test      IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Guarda o estado de uma sala
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                      I_EPISODE - ID do episódio
                                              I_ROOM - ID da sala
                                     I_PROF - ID do profissional, software e instituição
                                              I_STATUS -  Estado da sala
                                              I_NOTES - Notas
                                              I_TEST - Indica se deve validar o número de profissionais por categoria
                           SAIDA:   O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N)
          O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                                   O_ERROR - erro
    
      CRIAÇÃO: RB 2006/06/05
      NOTAS:
    *********************************************************************************/

    FUNCTION val_room_status
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_room      IN room.id_room%TYPE,
        i_prof      IN profissional,
        i_status    IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Valida o novo estado de uma sala
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                      I_EPISODE - ID do episódio
                                              I_ROOM - ID da sala
                                     I_PROF - ID do profissional, software e instituição
                                              I_STATUS -  Estado da sala
                           SAIDA:   O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N)
          O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                                   O_ERROR - erro
    
      CRIAÇÃO: RB 2006/10/18
      NOTAS:
    *********************************************************************************/

    FUNCTION val_pat_status
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_prof      IN profissional,
        i_status    IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Valida o novo estado de um paciente
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                      I_EPISODE - ID do episódio
                                     I_PROF - ID do profissional, software e instituição
                                              I_STATUS -  Estado da sala
                           SAIDA:   O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N)
          O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
          O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                                   O_ERROR - erro
    
      CRIAÇÃO: RB 2006/10/18
      NOTAS:   Valores possíveis do Estado da sala: F- Preparada, B- Ocupada, C- Em limpeza, D- Suja, P- Limpa, I- Suja e Infectada
    *********************************************************************************/

    FUNCTION get_grid_nurse_v1
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Obter o agendamento do dia do Bloco Operatório, para o enfermeiro. Devolve todas as
                          intervenções do dia a que o profissional esteja agendado - VISTA 1.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_DT - Data. se for nula, considera a data de sistema
                 I_PROF - ID do médico cirurgião que está a aceder à grelha
                                              I_TYPE - Indica se se pretende ver apenas os agendamentos aos quais o profissional
                                                está alocado ou todos os agendamentos. Valores possíveis:
                                                           A - Todos os agendamentos
                                                                P - Agendamentos do profissional
                           SAIDA:   O_GRID - array de agendamentos
                              O_ROOM - Array de estados possíveis das salas
                                        O_PAT - Array de estados possíveis do paciente
                                     O_ERROR - erro
    
      CRIAÇÃO: RB 2006/09/12
      NOTAS:
    *********************************************************************************/

    FUNCTION get_grid_nurse_v2
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter o agendamento do dia do Bloco Operatório, para o enfermeiro. Devolve todas as
                          intervenções do dia a que o profissional esteja agendado - VISTA 2.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_DT - Data. se for nula, considera a data de sistema
                 I_PROF - ID do enfermeiro que está a aceder à grelha
                                              I_TYPE - Indica se se pretende ver apenas os agendamentos aos quais o profissional
                                                está alocado ou todos os agendamentos. Valores possíveis:
                                                           A - Todos os agendamentos
                                                                P - Agendamentos do profissional
                           SAIDA:   O_GRID - array de agendamentos
                              O_ROOM - Array de estados possíveis das salas
                                        O_PAT - Array de estados possíveis do paciente
                                     O_ERROR - erro
    
      CRIAÇÃO: RB 2006/09/12
      NOTAS:
    *********************************************************************************/

    FUNCTION get_search_grid_aux_actv
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
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados ,
                    para os auxiliares
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
            I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
            I_CRIT_VAL - Lista de valores dos critérios de pesquisa
         I_INSTIT - Instituição
         I_EPIS_TYPE - Tipo de consulta
         I_DT - Data a pesquisar. Se for null assume a data de sistema
            I_PROF - ID do profissional q regista
         I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                 como é retornada em PK_LOGIN.GET_PROF_PREF
              Saida:   O_PAT - doentes activos
              O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                             O_WAIT_ICON - Nome do icone a mostrar quando não há data prevista para a realização da
                                cirurgia
         O_ERROR - erro
    
      CRIAÇÃO: RB 2006/11/19
      NOTAS:
    *********************************************************************************/

    FUNCTION get_search_grid_aux_inactv
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
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes INACTIVOS, de acordo com os critérios seleccionados ,
                    para os auxiliares
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
            I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
            I_CRIT_VAL - Lista de valores dos critérios de pesquisa
         I_INSTIT - Instituição
         I_EPIS_TYPE - Tipo de consulta
         I_DT - Data a pesquisar. Se for null assume a data de sistema
            I_PROF - ID do profissional q regista
         I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                 como é retornada em PK_LOGIN.GET_PROF_PREF
              Saida:   O_PAT - doentes activos
              O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
                             O_WAIT_ICON - Nome do icone a mostrar quando não há data prevista para a realização da
                                cirurgia
         O_ERROR - erro
    
      CRIAÇÃO: RB 2006/11/19
      NOTAS:
    *********************************************************************************/

    /**************************************************************************
    * Returns the list of consents to be handled by the administrative        *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_epis_documentation         epis documentation id               *
    * @param i_doc_area                   doc_area id                         *
    * @param i_doc_template               doc_template id                     *
    * @param i_flg_val_group              String to filter de group of rules  *
    * @param i_notes                      notes                               *
    * @param i_test                       Flag to execute validation          *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_consent_list               Cursor of consent list              *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/21                              *
    **************************************************************************/
    FUNCTION get_consent_admin_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_consent_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************
    * Returns the list POS to physician validate                                                    *
    *                                                                                               *
    * @param i_lang                       language id                                               *
    * @param i_prof                       professional, software and                                *
    *                                     institution ids                                           *
    * @param i_type                       type of search: D - Scheduled consults  for the physician,*
    *                                     C -Scheduled consults for the physician's clinical service*
    *                                                                                               *
    * @param o_POS_list                   Cursor of POS list                                        *
    * @param o_error                      Error message                                             *
    *                                                                                               *
    * @return                            Returns boolean                                            *
    *                                                                                               *
    * @author                            Filipe Silva                                               *
    * @version                           2.6.0.2                                                    *
    * @since                             2010/03/30                                                 *
    *************************************************************************************************/
    FUNCTION get_open_pos_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_type     IN VARCHAR2,
        o_pos_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_analysis_results
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_exams_results
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE initialize_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_type           Type of schedule for professional
    *                            A - All Schedule
    *                            P - Professional Schedule
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                Elisabete Bugalho
    * @Version               2.7.1.01
    * @since                 2017/04/10
    **********************************************************************************************/
    FUNCTION grid_surg_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_room_status
    (
        i_record IN NUMBER,
        i_type   IN VARCHAR2
    ) RETURN NUMBER;

    /********************************************************************************************** 
    * Returns a list of days with appointments for nurse grids
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_type           Type of schedule for professional
    *                            A - All Schedule
    *                            P - Professional Schedule
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                Elisabete Bugalho
    * @Version               2.7.1.01
    * @since                 2017/04/11
    **********************************************************************************************/
    FUNCTION get_grid_nurse_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_value_for_clinical_q
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_content           IN VARCHAR2,
        i_type              IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_sr_grid_tracking_view
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_room         IN VARCHAR2,
        i_pat_states   IN VARCHAR2,
        i_page         IN NUMBER,
        i_id_room      IN room.id_room%TYPE,
        i_waiting_room IN VARCHAR2,
        o_grid         OUT pk_types.cursor_type,
        o_room_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    -- EMR-437
    k_lf VARCHAR2(0010 CHAR) := chr(10);
    PROCEDURE setsql(i_sql IN VARCHAR2);
    g_sql VARCHAR2(32000);

    /**
    * Initialize parameters to be used in the grid query of ORIS
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/04/19
    */
    PROCEDURE init_params_patient_grids
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

    -- END EMR-437

    FUNCTION inactivate_surgery_admission
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    g_prof_anest_categ CONSTANT category_sub.id_category_sub%TYPE := pk_sysconfig.get_config('SR_ANEST_CATEG', 0, 0);
    g_prof_enf_instr   CONSTANT category_sub.id_category_sub%TYPE := pk_sysconfig.get_config('SR_ENF_INTR_CATEG', 0, 0);

    g_active    CONSTANT pat_blood_group.flg_status%TYPE := 'A';
    g_cancel    CONSTANT VARCHAR2(1) := 'C';
    g_default_y CONSTANT VARCHAR2(1) := 'Y';

    g_pat_status_pend    CONSTANT VARCHAR2(1) := 'A';
    g_sr_epis_type       CONSTANT PLS_INTEGER := pk_sysconfig.get_config('SR_EPIS_TYPE', 0, 0);
    g_epis_stat_inactive CONSTANT VARCHAR2(1) := 'I';
    g_epis_inactive      CONSTANT VARCHAR2(1) := 'I';
    g_interv_sec         CONSTANT VARCHAR2(1) := 'S';
    g_interv_canc        CONSTANT VARCHAR2(1) := 'C';

    --Estados do paciente
    --A-Ausente, W- Em espera, L- Pedido de transporte para o bloco, T- Em transporte para o bloco, V- Acolhido no bloco, P- Em preparação,
    --R- Preparado para a cirurgia, S- Em cirurgia, F- Terminou a cirurgia, Y- No recobro, D- Alta do Recobro, O- Em transporte para outro local no hospital ou noutra instituição,
    --C- Cirurgia cancelada
    g_pat_status_a CONSTANT VARCHAR2(1) := 'A';
    g_pat_status_w CONSTANT VARCHAR2(1) := 'W';
    g_pat_status_l CONSTANT VARCHAR2(1) := 'L';
    g_pat_status_t CONSTANT VARCHAR2(1) := 'T';
    g_pat_status_v CONSTANT VARCHAR2(1) := 'V';
    g_pat_status_p CONSTANT VARCHAR2(1) := 'P';
    g_pat_status_r CONSTANT VARCHAR2(1) := 'R';
    g_pat_status_s CONSTANT VARCHAR2(1) := 'S';
    g_pat_status_f CONSTANT VARCHAR2(1) := 'F';
    g_pat_status_y CONSTANT VARCHAR2(1) := 'Y';
    g_pat_status_d CONSTANT VARCHAR2(1) := 'D';
    g_pat_status_o CONSTANT VARCHAR2(1) := 'O';
    g_pat_status_c CONSTANT VARCHAR2(1) := 'C';

    --Estados da sala. Valores possíveis: F- Preparada, B- Ocupada, C- Em limpeza, D- Suja, P- Limpa, I- Suja e Infectada
    g_room_status_f CONSTANT VARCHAR2(1) := 'F';
    g_room_status_b CONSTANT VARCHAR2(1) := 'B';
    g_room_status_c CONSTANT VARCHAR2(1) := 'C';
    g_room_status_d CONSTANT VARCHAR2(1) := 'D';
    g_room_status_p CONSTANT VARCHAR2(1) := 'P';
    g_room_status_i CONSTANT VARCHAR2(1) := 'I';

    g_no_status_icon CONSTANT VARCHAR2(30) := 'DrugInTransportIcon';

    g_trunc_dt_format CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('TRUNC_DT_FORMAT', 0, 0);
    g_sysdate_char          VARCHAR2(50);
    g_date_hour_send_format VARCHAR2(50);
    g_day_in_seconds CONSTANT NUMBER := 86399; -- 23:59:59 in seconds

    g_my_patients  CONSTANT VARCHAR2(1) := 'P';
    g_all_patients CONSTANT VARCHAR2(1) := 'A';
    g_waiting_icon CONSTANT VARCHAR2(20) := 'WaitingIcon';

    -- Flag referente ao Inicio da Cirurgia
    flg_interv_start CONSTANT VARCHAR2(2) := 'IC';
    -- Status Active
    flg_status_a CONSTANT VARCHAR2(1) := 'A';
    -- Status Cancelled
    flg_status_c CONSTANT VARCHAR2(1) := 'C';

    g_pat_allergy_cancel CONSTANT pat_allergy.flg_status%TYPE := 'C';
    g_flg_without        CONSTANT VARCHAR2(2) := 'YF';

    g_flg_type_rec CONSTANT epis_prof_rec.flg_type%TYPE := 'R';

    --Sub-categoria Cirurgião Responsável
    g_catg_surg_resp CONSTANT category_sub.id_category%TYPE := 1;

    g_pat_history_diagnosis_n CONSTANT VARCHAR2(1) := 'N';

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';

    g_analysis_exam_icon_grid_rank sys_domain.code_domain%TYPE := 'ANALYSIS_EXAM_ICON_GRID_RANK';

    g_flg_ehr_normal CONSTANT VARCHAR2(1) := 'N';
    g_flg_ehr        CONSTANT VARCHAR2(1) := 'E';

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_inst_grp_flg_rel_adt CONSTANT institution_group.flg_relation%TYPE := 'ADT';

    g_sr_consent_a CONSTANT VARCHAR2(1) := 'A';
    g_sr_consent_o CONSTANT VARCHAR2(1) := 'O';
    g_sr_consent_i CONSTANT VARCHAR2(1) := 'I';

    g_sr_proc_a CONSTANT VARCHAR2(1) := 'A';
    g_sr_proc_p CONSTANT VARCHAR2(1) := 'P';

    g_scheduled_consult     CONSTANT VARCHAR(1) := 'C';
    g_consult_dep_clin_serv CONSTANT VARCHAR(1) := 'T';

    g_sr_epis_interv_c CONSTANT VARCHAR2(1) := 'C';

    g_cf_pat_gender_abbr CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT.GENDER.ABBR';
END;
/
