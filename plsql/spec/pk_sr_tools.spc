/*-- Last Change Revision: $Rev: 2028988 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_tools AS

    FUNCTION get_prof_teams
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_search IN VARCHAR2,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem  a lista de equipas a que um profissional pertence numa dada instituição
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                                              I_SEARCH - String de pesquisa
                           SAIDA:   O_LIST - Array com as equipas do profissional
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: RB 2006/10/13
      NOTAS:
    *********************************************************************************/

    FUNCTION get_prof_team_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem  a lista de profissionais pertencentes a uma equipa
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                                              I_PROF_TEAM - ID da equipa de profissionais
                           SAIDA:   O_LIST - Array com as equipas do profissional
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: RB 2006/10/13
      NOTAS:
    *********************************************************************************/

    FUNCTION get_prof_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_team_name OUT VARCHAR2,
        o_team_desc OUT VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem  a lista de profissionais pertencentes a uma equipa
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                                              I_PROF_TEAM - ID da equipa de profissionais
                           SAIDA:   O_TEAM_NAME - Nome da equipa
                                    O_TEAM_DESC - Descrição da equipa
                                    O_LIST - Array com as equipas do profissional
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: RB 2006/10/13
      NOTAS:
    *********************************************************************************/

    FUNCTION get_prof_team_search
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        i_search_prof IN VARCHAR2,
        i_search_spec IN VARCHAR2,
        i_search_num  IN VARCHAR2,
        i_excl_prof   IN table_number,
        o_list        OUT pk_types.cursor_type,
        o_icon        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Procura um dado profissional, de acordo com os critérios de pesquisa definidos, para
                    adicionar à equipa de profissionais. Não mostra os profissionais já seleccionados para esta
                            equipa.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                                              I_PROF_TEAM - ID da equipa de profissionais
                                              I_SEARCH_PROF - Critério de pesquisa do profissional
                                              I_SEARCH_SPEC - Critério de pesquisa da especialidade
                                              I_SEARCH_NUM - Critério de pesquisa do nº mecanográfico
                                I_EXCL_PROF - Array com os IDs dos profissionais a excluir do resultado da pesquisa
                           SAIDA:   O_LIST - Array com as equipas do profissional
                                    O_ICON - Nome do icone a mostrar para identificar os profissionais seleccionados
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: RB 2006/10/13
      NOTAS:
    *********************************************************************************/

    FUNCTION get_prof_catg_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Mostra a lista de categorias que podem ser atribuídas ao profissional
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_LIST - Array com as equipas do profissional
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: RB 2006/10/13
      NOTAS:
    *********************************************************************************/

    FUNCTION get_prof_room_nurse
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Obter listagem das escolhas de: departamento, salas
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - profissional (id, institution, software)
                    Saída:   O_LIST - listagem das instituições
                             O_ERROR - erro
      CRIAÇÃO: RB 2006/10/30
      NOTAS:
    ******************************************************************************************************/

    FUNCTION set_prof_room_nurse
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        i_catg  IN category_sub.id_category_sub%TYPE,
        i_shift IN sr_prof_shift.id_sr_prof_shift%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Alterar a sala preferencial e a sub categoria dos enfermeiros do bloco
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - profissional (ID, INSTITUTION, SOFTWARE)
                             I_ROOM - array de salas preferenciais (podem ser várias, uma por departamento)
                                         I_CATG - array de categorias profissionais. Apenas pode ser preenchida na linha da sala preferencial
                                         I_SHIFT - ID do turno
                    Saída:   O_ERROR - erro
      CRIAÇÃO: RB 2006/10/30
      NOTAS:
    ******************************************************************************************************/

    FUNCTION get_nurse_catg_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Alterar a sala preferencial e a sub categoria dos enfermeiros do bloco
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - profissional (ID, INSTITUTION, SOFTWARE)
                    Saída:   O_LIST - Array com as sub-categorias de enfermagem
                                    O_ERROR - erro
      CRIAÇÃO: RB 2006/10/30
      NOTAS:
    ******************************************************************************************************/

    FUNCTION get_nurse_shift_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Obtem a lista de turnos de enfermagem do bloco operatório
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                             I_PROF - profissional (ID, INSTITUTION, SOFTWARE)
                    Saída:   O_LIST - Array com as sub-categorias de enfermagem
                                    O_ERROR - erro
      CRIAÇÃO: RB 2006/10/30
      NOTAS:
    ******************************************************************************************************/

    FUNCTION set_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_team    IN prof_team.id_prof_team%TYPE,
        i_name         IN prof_team.prof_team_name%TYPE,
        i_desc         IN prof_team.prof_team_desc%TYPE,
        i_tbl_prof     IN table_number,
        i_tbl_catg     IN table_number,
        i_tbl_status   IN table_varchar,
        i_test         IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Cria/actualiza a informação relativa a uma equipa.
                    Validações:
                        - A equipa tem que ter um e apenas um responsável
                        - A equipa não pode ter profissionais sem categoria associada
                        - Valida o número de profissionais por categoria (se I_TEST=Y) e apresenta mensagem
                            com os limites excedidos para que o utilizador confirme.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                                I_PROF_TEAM - ID da equipa na PROF_TEAM que deu origem à equipa de cirurgia
                                I_NAME - Nome da equipa
                                I_DESC - Descrição da equipa.
                                I_TBL_PROF - Array com os ids dos profissionais na equipa
                                I_TBL_CATG - Array com as categorias para cada um dos profissionais em I_TBL_PROF
                                I_TBL_STATUS - Array com o estado de actualização para cada profissional em I_TBL_PROF. Valores possíveis:
                                                'N' - Novo registo
                                                'C' - Actualização registo
                                                'D' - Remover registo
                                              I_TEST - Indica se deve validar o número de profissionais por categoria
                           SAIDA:   O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N)
                            O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
                            O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
                            O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: Rui Campos 2006/11/16
      NOTAS:
    *********************************************************************************/

    FUNCTION get_sr_prof_team_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_type           IN VARCHAR2,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_id_prof_team   OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name      OUT VARCHAR2,
        o_team_desc      OUT VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_status         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Obtem  a lista de equipas a que um profissional pertence numa dada instituição
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_TYPE                   Type of access (P-Cirurgia Proposta; R-Registo de Intervenção)
    *
    * @param O_ID_PROF_TEAM           ID da equipa de profissionais
    * @param O_TEAM_NAME              Team Name
    * @param O_TEAM_DESC              Team Description  
    * @param O_LIST                   Array com as equipas associadas ao episódio
    * @param O_STATUS                 Cursor com informação acerca da última actualização da equipa.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Rui Campos 
    * @version                        0.1
    * @since                          2006/11/14
    *******************************************************************************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        o_id_prof_team OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name    OUT VARCHAR2,
        o_team_desc    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Obtem  a lista de equipas a que um profissional pertence numa dada instituição
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_TYPE                   Type of access (P-Cirurgia Proposta; R-Registo de Intervenção)
    * @param I_FLG_REPORT_TYPE        Report type: C-complete; D-detailed    
    *
    * @param O_ID_PROF_TEAM           ID da equipa de profissionais
    * @param O_TEAM_NAME              Team Name
    * @param O_TEAM_DESC              Team Description  
    * @param O_LIST                   Array com as equipas associadas ao episódio
    * @param O_STATUS                 Cursor com informação acerca da última actualização da equipa.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Rui Campos 
    * @version                        0.1
    * @since                          2006/11/14
    *******************************************************************************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_type            IN VARCHAR2,
        i_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE DEFAULT NULL,
        i_flg_report_type IN VARCHAR2, --C-complete; D-detailed
        o_id_prof_team    OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name       OUT VARCHAR2,
        o_team_desc       OUT VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_status          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_sr_prof_team_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_surgery_record  IN sr_surgery_record.id_surgery_record%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_prof_team       IN prof_team.id_prof_team%TYPE,
        i_tbl_prof        IN table_number,
        i_tbl_catg        IN table_number,
        i_tbl_status      IN table_varchar,
        i_test            IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_msg_text        OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Cria/actualiza a informação relativa à equipa associada ao episódio de cirurgia.
                    Validações:
                        - A equipa tem que ter um e apenas um responsável
                        - A equipa não pode ter profissionais sem categoria associada
                        - Valida o número de profissionais por categoria (se I_TEST=Y) e apresenta mensagem
                            com os limites excedidos para que o utilizador confirme.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                                I_SURGERY_RECORD - ID do registo de intervenção (Opcional).
                                              I_EPISODE - ID do episódio
                                I_PROF_TEAM - ID da equipa na PROF_TEAM que deu origem à equipa de cirurgia
                                I_TBL_PROF - Array com os ids dos profissionais na equipa
                                I_TBL_CATG - Array com as categorias para cada um dos profissionais em I_TBL_PROF
                                I_TBL_STATUS - Array com o estado de actualização para cada profissional em I_TBL_PROF. Valores possíveis:
                                                NULL - Novo registo a partir de equipa escolhida pelo utilizador (sem alteração)
                                                'N' - Novo registo
                                                'C' - Actualização registo
                                                'D' - Remover registo
                                              I_TEST - Indica se deve validar o número de profissionais por categoria
                           SAIDA:   O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N)
                            O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
                            O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
                            O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: Rui Campos 2006/11/16
      NOTAS:
    *********************************************************************************/

    FUNCTION get_sr_prof_team_search
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_search_prof IN VARCHAR2,
        i_search_spec IN VARCHAR2,
        i_search_num  IN VARCHAR2,
        i_excl_prof   IN table_number,
        i_type        IN VARCHAR2,
        o_list        OUT pk_types.cursor_type,
        o_icon        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Procura um dado profissional, de acordo com os critérios de pesquisa definidos, para
                    adicionar à equipa de profissionais. Não mostra os profissionais já seleccionados para esta
                            equipa.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                                              I_EPISODE - ID do episódio
                                              I_SEARCH_PROF - Critério de pesquisa do profissional
                                              I_SEARCH_SPEC - Critério de pesquisa da especialidade
                                              I_SEARCH_NUM - Critério de pesquisa do nº mecanográfico
                                I_EXCL_PROF - Array com os IDs dos profissionais a excluir do resultado da pesquisa (Para situações
                                                em que no ecrã já foram adicionados profissionais à equipa mas esta ainda não foi gravada).
                                I_TYPE - Tipo de acesso (P-Cirurgia Proposta; R-Registo de Intervenção)
                           SAIDA:   O_LIST - Array com as equipas do profissional
                                    O_ICON - Nome do icone a mostrar para identificar os profissionais seleccionados
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: Rui Campos 2006/11/23
      NOTAS:
    *********************************************************************************/

    FUNCTION get_prof_category_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_professional IN professional.id_professional%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Mostra a lista de categorias que podem ser atribuídas ao profissional
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                              I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_LIST - Array com as equipas do profissional
                                    O_ERROR - Descrição do erro
    
      CRIAÇÃO: RB 2006/10/13
      NOTAS:
    *********************************************************************************/

    FUNCTION cancel_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************************************
       OBJECTIVO: Alterar a sala preferencial e/ou cancelar
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                    I_PROF - profissional (ID, INSTITUTION, SOFTWARE)
                    I_ROOM - ID da sala cancelada
            Saída:   O_ERROR - erro
      CRIAÇÃO: RB 2007/02/01
      NOTAS:
    ******************************************************************************************************/
    /********************************************************************************************
    * Returns yes or not if the professional is on the surgical team 
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    *                        
    * @return  Yes or no 
    * 
    * @author                         Filipe Silva
    * @version                        2.6
    * @since                          26-01-2010
    **********************************************************************************************/

    FUNCTION get_sr_prof_team
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN PLS_INTEGER;

    FUNCTION set_sr_prof_team_det_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_surgery_record    IN sr_surgery_record.id_surgery_record%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_episode_context   IN episode.id_episode%TYPE,
        i_prof_team         IN prof_team.id_prof_team%TYPE,
        i_tbl_prof          IN table_number,
        i_tbl_catg          IN table_number,
        i_tbl_status        IN table_varchar,
        i_test              IN VARCHAR2,
        i_dt_reg            IN sr_prof_team_det.dt_reg_tstz%TYPE DEFAULT NULL,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE DEFAULT NULL,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_text          OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVE:   CALL SET_SR_PROF_TEAM_DET without commit in the end
       PARAMETERS:  ENTRADA: I_LANG - Language ID
                             I_PROF - Professional object
                             I_SURGERY_RECORD - Surgery Record ID
                             I_EPISODE - Episode ID
                             I_PROF_TEAM - Team ID
                             I_TBL_PROF - Team professionals table
                             I_TBL_CATG - Professionals category table
                             I_TBL_STATUS - Professional status table
                                          NULL - new record
                                          'N' - new record
                                          'C' - update
                                          'D' - delete
                             I_TEST - Validate team?
                    SAIDA:   O_FLG_SHOW - Display message?
                             O_MSG_TITLE - Message title
                             O_MSG_TEXT - Message Text
                             O_BUTTON - Displayed buttons N - no, R - read, C - confirm
                             O_ERROR - error returned
    
      CREATED: Sergio Dias 2010/09/14
      NOTES: ALERT-116342
    *********************************************************************************/

    FUNCTION get_sr_interv_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error          OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION get_sr_interv_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_team_number
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN NUMBER;

    FUNCTION get_principal_team
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN VARCHAR2;

    FUNCTION get_team_grid_tooltip
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN VARCHAR2;

    FUNCTION get_team_profissional
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN VARCHAR2;

    FUNCTION get_sr_interv_team_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_prof_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Cancelar a equipa de um procedimento cirurgico
    *
    * @param i_lang           Id do idioma
    * @param i_sr_epis_interv Dados do registo a actualizar
    *
    * @param o_error          Mensagem de erro
    *
    * @return                 TRUE/FALSE
    *
    * @author                 Rita Lopes
    * @since                  2011/10/27
       ********************************************************************************************/

    FUNCTION cancel_sr_prof_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_sr_prof_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_id_prof_team_det  IN sr_prof_team_det.id_sr_prof_team_det%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_sr_prof_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sr_interv_team_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Cancelar registos da equipa na tabela SR_PROF_TEAM_DET_HIST
    *
    * @param i_lang             Id do idioma
    * @param i_sr_epis_interv   Id sr_epis_interv
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/04/24
       ********************************************************************************************/

    FUNCTION cancel_sr_prof_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sr_prof_team_member
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION set_sr_prof_team_det_interface
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_surgery_record    IN sr_surgery_record.id_surgery_record%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_episode_context   IN episode.id_episode%TYPE,
        i_prof_team         IN prof_team.id_prof_team%TYPE,
        i_tbl_prof          IN table_number,
        i_tbl_catg          IN table_number,
        i_tbl_status        IN table_varchar,
        i_test              IN VARCHAR2,
        i_id_sr_epis_interv IN sr_prof_team_det.id_sr_epis_interv%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_text          OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_sr_dept      INTEGER;
    g_found        BOOLEAN;

    g_flg_available CONSTANT VARCHAR2(1) := 'Y';
    g_flg_active    CONSTANT VARCHAR2(1) := 'A';
    g_flg_inactive  CONSTANT VARCHAR2(1) := 'I';
    g_cancel        CONSTANT VARCHAR2(1) := 'C';
    g_handsel_icon  CONSTANT VARCHAR2(20) := 'HandSelectedIcon';

    g_cat_doctor CONSTANT VARCHAR2(1) := 'D';
    g_cat_nurse  CONSTANT VARCHAR2(1) := 'N';

    g_prof_room_pref  CONSTANT prof_room.flg_pref%TYPE := 'Y';
    g_prof_room_npref CONSTANT prof_room.flg_pref%TYPE := 'N';
    g_flg_type_nurse  CONSTANT category.flg_type%TYPE := 'N';
    g_flg_type_doctor CONSTANT category.flg_type%TYPE := 'D';

    g_catg_resp CONSTANT category_sub.id_category_sub%TYPE := 1;

    --- Status para o método SET_PROF_TEAM.I_TBL_STATUS
    g_status_new CONSTANT VARCHAR2(1) := 'N';
    g_status_chg CONSTANT VARCHAR2(1) := 'C';
    g_status_del CONSTANT VARCHAR2(1) := 'D';

    -- Status para SR_PROF_TEAM_DET.FLG_STATUS
    g_status_active CONSTANT VARCHAR2(1) := 'A';
    g_status_cancel CONSTANT VARCHAR2(1) := 'C';

    -- I_TYPE para o método GET_SR_PROF_TEAM_DET
    flg_type_surg_record CONSTANT VARCHAR2(1) := 'R';
    flg_type_propos_surg CONSTANT VARCHAR2(1) := 'P';

    g_value_y      CONSTANT VARCHAR2(1) := 'Y';
    g_flg_type_rec CONSTANT epis_prof_rec.flg_type%TYPE := 'R';

    -- report types
    g_report_complete_c CONSTANT VARCHAR2(1) := 'C';
    g_report_detail_d   CONSTANT VARCHAR2(1) := 'D';
END pk_sr_tools;
/
