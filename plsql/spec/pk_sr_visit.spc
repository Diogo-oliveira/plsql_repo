/*-- Last Change Revision: $Rev: 2028989 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_visit AS

    /********************************************************************************************
    * Criar uma visita. Esta visita é criada obrigatoriamente quando desejamos criar um episódio de 
    *  bloco operatório, que será utilizado para planeamento de uma cirurgia antes do paciente 
    *  iniciar propriamente o episódio. 
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_flg_temp         Indica se é um episódio temporário
    * @param i_id_episode_ext   ID do episódio externo
    * @param i_flg_ehr          Tipo de episódio: N- Normal, S- Planeamento, E- EHR
    * @param i_num_episode_prev id from previous SONHO episode
    * @param i_cod_module       type of module which originated previous episode
    * @param io_episode         ID do episódio criado
    * @param io_visit           ID da visita criada
    * @param i_id_dcs_requested ID da dep_clin_serv
    * @param i_dt_creation      data de criação do episódio (migração de episódios)
    * @param i_dt_begin         data de início do episódio (migração de episódios)
    * @param i_flg_migration    flag de migração M-migrado A-normal (migração de episódios)
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/01/31 
    * @altered by               Filipe Silva
    * @Date                     2009/07/01
    * @Notas                    create episode with the dep_clin_serv (ALERT - 30974)
    * @altered by               Filipe Silva
    * @Date                     2009/07/01
    * @Notas                    ALERT - 31101
    * @altered by               Sérgio Dias
    * @date                     2010/08/20
    * @Notas                    create episode by migration (ALERT-118077)
    ********************************************************************************************/
    FUNCTION create_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_flg_temp       IN epis_info.flg_unknown%TYPE,
        i_id_episode_ext IN VARCHAR2,
        i_flg_ehr        IN episode.flg_ehr%TYPE,
        /*BEGIN ALERT - 31101*/
        i_num_episode_prev IN epis_ext_sys.value%TYPE,
        i_cod_module       IN epis_ext_sys.cod_epis_type_ext%TYPE,
        /*END ALERT - 31101*/
        i_id_dcs_requested IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE,
        i_dt_creation      IN episode.dt_creation%TYPE DEFAULT NULL,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_flg_migration    IN episode.flg_migration%TYPE DEFAULT NULL,
        io_episode         IN OUT episode.id_episode%TYPE,
        io_visit           IN OUT visit.id_visit%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criar registo na tabela SCHEDULE que permita o registo de informações relativas ao agendamento.
    *
    * @param i_lang             Id do idioma
    * @param i_schedule         Rowtype da tabela SCHEDULE
    * @param i_episode          episode identifier
    * @param o_schedule         ID do registo criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/12/09 
    ********************************************************************************************/
    FUNCTION create_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_schedule IN schedule%ROWTYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_schedule OUT schedule.id_schedule%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criar registo na tabela SCHEDULE_SR que permita o registo de informações relativas à cirurgia.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             professional identifier
    * @param i_schedule_sr      Rowtype da tabela SCHEDULE_SR 
    * @param o_schedule_sr      ID do registo criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/01/31
    ********************************************************************************************/
    FUNCTION create_schedule_sr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_schedule_sr IN schedule_sr%ROWTYPE,
        o_schedule_sr OUT schedule_sr.id_schedule_sr%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criar registo na tabela SR_SURGERY_RECORD que permita o registo de informações relativas à cirurgia.
    *
    * @param i_lang             Id do idioma
    * @param i_sr_surg_rec      Rowtype da tabela SR_SURGERY_RECORD
    * @param i_prof             professional identifier
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/01/31 
    ********************************************************************************************/
    FUNCTION create_surgery_record
    (
        i_lang        IN language.id_language%TYPE,
        i_sr_surg_rec IN sr_surgery_record%ROWTYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Lista de episódios de bloco operatório para o doente indicado. 
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_status           Estado do episódio
    * @param i_planned          cirurgia planeada
    * 
    * @param o_grid             Array de episódios de bloco operatório
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_room             Array com as salas do Bloco Operatório
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/08/28 
    ********************************************************************************************/
    FUNCTION get_pat_surg_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        i_status   IN VARCHAR2,
        i_planned  IN VARCHAR2,
        o_grid     OUT pk_types.cursor_type,
        o_status   OUT pk_types.cursor_type,
        o_room     OUT pk_types.cursor_type,
        o_id_disch OUT disch_reas_dest.id_disch_reas_dest%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Returns Surgery Request episodes for a specific Scope - for Reports 
    * 
    * @param  I_LANG                   Language ID for translations
    * @param  I_PROF                   Professional vector of information (professional ID, institution ID, software ID)    
    * @param  I_SCOPE                  Scope ID (E-Episode ID, V-Visit ID, P-Patient ID)
    * @param  I_FLG_SCOPE              Scope type
    * @param  I_START_DATE             Start date for temporal filtering
    * @param  I_END_DATE               End date for temporal filtering
    * @param  I_CANCELLED              Indicates whether the records should be returned canceled
    * @param  I_CRIT_TYPE              Flag that indicates if the filter time to consider all records or only during the executions
    * @param  I_FLG_REPORT             Flag used to remove formatting
    * @param  I_FLG_CONTEXT            Grid information aggregated or not
    * @param  I_STATUS                 Episode state
    * @param  I_PLANNED                Planned Surgery
    * @param  O_GRID                   Cursor that returns Episodes for Operating Room in the current Scope
    * @param  O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @value  I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value  I_FLG_SCOPE              {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value  I_CANCELLED              {*} 'Y' Yes {*} 'N' No
    * @value  I_CRIT_TYPE              {*} 'A' All {*} 'E' Execution
    * @value  I_FLG_REPORT             {*} 'Y' Yes {*} 'N' No
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.1
    * @since                          20-May-2011
    *
    * @author                         António Neto
    * @version                        2.6.1.5
    * @since                          09-Nov-2011
    *
    * @dependencies                   REPORTS
    *******************************************************************************************************************************************/
    FUNCTION get_pat_surg_episodes_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        i_status     IN VARCHAR2,
        i_planned    IN VARCHAR2,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_all_surgery
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN OUT patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_episode_new OUT episode.id_episode%TYPE,
        o_schedule    OUT schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
           de existir um agendamento, diagnóstico base e intervenção a realizar definidos. Se o paciente não for
       preenchido, cria um novo paciente (temporário) 
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                      I_PATIENT - ID do paciente
                                         I_PROF - ID do profissional, instituição e software
           Saida:   O_EPISODE_NEW - Novo episodio criado
           O_SCHEDULE - ID do agendamento criado
                        O_ERROR - erro 
     
      CRIAÇÃO: RB 2006/08/29 
    
      NOTAS: 
    *********************************************************************************/

    /********************************************************************************************
    * Get list of all surgery rooms
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_room             Lista de quartos
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Luís Maia
    * @since                    2011/Jun/01
    ********************************************************************************************/
    FUNCTION get_rooms_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_room  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Actualiza a data prevista de realização de uma cirurgia na criação de um novo processo cirúrgico.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_schedule_sr      ID do agendamento
    * @param i_dt               Data prevista da realização da cirurgia
    * @param i_test             Test if there is already one cirurgic episode for selected day ('Y'-yes; 'N'-no)
    * @param i_duration         New duration in minutes
    * @param i_room             New cirurgic room
    * 
    * @param o_flg_show         Indica de deve ou não ser mostrada uma mensagem de aviso
    * @param o_msg_title        Título da mensagem
    * @param o_msg_text         Descrição da mensagem
    * @param o_button           Botões a disponibilizar
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Luís Maia
    * @since                    2011/Jun/01
    ********************************************************************************************/
    FUNCTION set_surg_proc_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_schedule_sr IN schedule_sr.id_schedule_sr%TYPE,
        i_dt          IN VARCHAR2,
        i_test        IN VARCHAR2,
        i_duration    IN schedule_sr.duration%TYPE,
        i_room        IN room.id_room%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    *  de existir um agendamento, diagnóstico base e intervenção a realizar definidos (NOVO PROCESSO CIRÚRGICO)
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_prev_episode     Id do episódio de consulta, urgência ou internamento ao qual o episódio de bloco
    *                            irá ficar associado
    * @param i_type             Tipo de cirurgia: C-Convencional, A- Ambulatória
    * @param i_dt_surg          Data prevista para a realização da cirurgia
    * @param i_room             ID da sala prevista para a realização da cirurgia
    * @param i_duration         Duração prevista da cirurgia (em segundos, por causa do SONHO)
    * @param i_flg_ehr          Tipo de episódio: N- Normal, S- Planeamento, E- EHR
    * 
    * @param o_episode_new      ID do novo episodio criado
    * @param o_schedule         ID do agendamento criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2007/05/31
    ********************************************************************************************/
    FUNCTION create_all_surgery
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN OUT patient.id_patient%TYPE,
        i_prof         IN profissional,
        i_prev_episode IN episode.id_prev_episode%TYPE,
        i_type         IN VARCHAR2,
        i_dt_surg      IN VARCHAR2,
        i_room         IN room.id_room%TYPE,
        i_duration     IN schedule_sr.duration%TYPE,
        i_flg_ehr      IN episode.flg_ehr%TYPE,
        o_episode_new  OUT episode.id_episode%TYPE,
        o_schedule     OUT schedule.id_schedule%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Get Advanced Input for cipe interventions.
    *
    * @param      I_LANG            number, default language
    * @param      I_PROF            object type, health profisisonal
    * @param      I_EPIS_INTERV     Intervention ID
    * @param      O_FIELDS          varchar array, intervention notes
    * @param      O_FIELDS_DET      varchar array, intervention notes
    * @param      O_ERROR           erro
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Tércio Soares
    * @version    0.1
    * @since      2007/06/05
    */
    FUNCTION get_advanced_input
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN schedule_sr.id_episode%TYPE,
        o_fields     OUT pk_types.cursor_type,
        o_fields_det OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************/

    /** @headcom
    * Get field's value for the Advanced Input of cipe interventions.
    *
    * @param      I_LANG            Preferred language ID for this professional
    * @param      I_PROF            Object (professional ID, institution ID, software ID)
    * @param      I_ID_ADVANCED_INPUT    Advanced Input ID
    * @param      I_EPIS_INTERV     Intervention ID
    *
    * @return     type t_cipe_advanced_input
    * @author     Tércio Soares
    * @version    0.1
    * @since      2007/06/05
    */
    FUNCTION get_adv_input_field_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_id_episode        IN schedule_sr.id_episode%TYPE
    ) RETURN t_coll_srvisit_adv_input
        PIPELINED;

    /********************************************************************************************
    * Função Interna: Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    *  de existir um agendamento, diagnóstico base e intervenção a realizar definidos (NOVO PROCESSO CIRÚRGICO)
    *
    * @param i_lang             Id do idioma
    * @param i_patient          ID do paciente
    * @param i_prof             ID do profissional, instituição e software
    * @param i_visit            ID da visita. Vem preenchido quando o episódio tem origem noutro produto Alert
    * @param i_flg_ehr          Tipo de episódio: N- Normal, S- Planeamento, E- EHR
    * @param i_id_dcs_requested ID da dep_clin_serv
    * @param i_dt_creation      data de criação do episódio (migração de episódios)
    * @param i_dt_begin         Data de início do episódio (migração de episódios)
    * @param i_num_episode_prev ID do episódio associado (migração de episódios)
    * @param i_flg_migration    flag de migração M-migrado A-normal (migração de episódios)
    * @param i_id_room          quarto onde vai ser agendado (migração de episódios)
    * 
    * @param o_episode_new      ID do novo episodio criado
    * @param o_schedule         ID do agendamento criado
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2007/05/24
    * @altered by               Rita Lopes
    * @                         2008/04/17
    * @Notas                    Parametrizei na sys_config para ir buscar o dep_clin_serv   
    * @altered by               Filipe Silva
    * @date                     2009/07/01
    * @Notas                    create episode with the dep_clin_serv (ALERT - 30974)
    * @altered by               Sérgio Dias
    * @date                     2010/08/20
    * @Notas                    create episode by migration (ALERT-118077)
    ********************************************************************************************/
    FUNCTION create_all_surgery_int
    (
        i_lang             IN language.id_language%TYPE,
        i_patient          IN OUT patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_visit            IN visit.id_visit%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_id_dcs_requested IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_creation      IN episode.dt_creation%TYPE DEFAULT NULL,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE DEFAULT NULL,
        i_id_episode_ext   IN epis_ext_sys.value%TYPE DEFAULT NULL,
        i_flg_migration    IN episode.flg_migration%TYPE DEFAULT NULL,
        i_id_room          IN room.id_room%TYPE DEFAULT NULL,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        i_inst_dest        IN NUMBER DEFAULT NULL,
        o_episode_new      OUT episode.id_episode%TYPE,
        o_schedule         OUT schedule.id_schedule%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criar registo de episódio de consulta, associado a agendamento. 
    *   Se existem episódios activos p/ esta visita, são fechados!! 
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_visit            ID da visita. Pode não vir preenchido 
    * @param i_flg_temp         Indica se é um episódio temporário
    * @param i_id_episode_ext   ID do episódio externo
    * @param i_date_str         Data (visita)
    * @param io_episode         ID do episódio criado
    * @param i_flg_ehr          Tipo de episódio: N- Normal, S- Planeamento, E- EHR
    * @param i_num_episode_prev id from previous SONHO episode
    * @param i_cod_module       type of module which originated previous episode
    * @param i_flg_migration    flag de migração M-migrado A-normal (migração de episódios)
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Teresa Coutinho
    * @since                    2008/04/08
    * @altered by               Filipe Silva
    * @date                     2009/07/01
    * @Notas                    ALERT - 31101
    * @altered by               Sérgio Dias
    * @date                     2010/08/20
    * @Notas                    create episode by migration (ALERT-118077)
    ********************************************************************************************/
    FUNCTION create_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_visit          IN visit.id_visit%TYPE,
        i_flg_temp       IN epis_info.flg_unknown%TYPE,
        i_id_episode_ext IN VARCHAR2,
        i_dt_creation    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_episode       IN OUT episode.id_episode%TYPE,
        i_flg_ehr        IN episode.flg_ehr%TYPE,
        /*BEGIN ALERT 31101*/
        i_num_episode_prev IN epis_ext_sys.value%TYPE,
        i_cod_module       IN epis_ext_sys.cod_epis_type_ext%TYPE,
        /*END ALERT 31101*/
        i_id_dcs_requested IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_migration    IN episode.flg_migration%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Verifica se a instituição tem o produto i_prof.software instalado 
    *
    * @param i_institution      ID da instituição
    * @param i_software         ID do software
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2008/05/27
    ********************************************************************************************/
    FUNCTION check_exists_software
    (
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
    * de existir um agendamento, diagnóstico base e intervenção a realizar definidos. 
    * O paciente tem que ser fornecido. 
    *
    * @param i_lang             Id do idioma
    * @param i_id_prof          ID do profissional
    * @param i_id_institution   ID da instituição
    * @param i_id_software      ID do software
    * @param i_patient          ID do paciente
    * 
    * @param o_schedule         ID do agendamento criado
    * @param o_ora_sqlcode      Código do erro oracle
    * @param o_ora_sqlerrm      Descrição do erro oracle
    * @param o_err_desc         Descrição do erro
    * @param o_err_action       Descrição da acção a ser tomada
    *
    * @return                   ID do novo episodio criado; -1 em caso de erro; 
    *
    * @author                   Alexandre Santos
    * @since                    2009/03/23 
    ********************************************************************************************/
    FUNCTION create_all_surgery
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN NUMBER,
        i_id_institution IN NUMBER,
        i_id_software    IN NUMBER,
        i_patient        IN OUT patient.id_patient%TYPE,
        i_id_ext_sys     IN external_sys.id_external_sys%TYPE DEFAULT NULL,
        i_value          IN epis_ext_sys.value%TYPE DEFAULT NULL,
        o_schedule       OUT schedule.id_schedule%TYPE,
        o_ora_sqlcode    OUT VARCHAR2,
        o_ora_sqlerrm    OUT VARCHAR2,
        o_err_desc       OUT VARCHAR2,
        o_err_action     OUT VARCHAR2
    ) RETURN NUMBER;

    /**************************************************************************
    * Check icon status for the surgical procedure                            *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns string with icon format         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/16                              *
    **************************************************************************/
    FUNCTION check_icon_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Sets an episode as admitted.
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_epis                  I_EPIS   Id of the episode to    
    * @param      O_ERROR an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   2009/10/23
    **********************************************************************************************/
    FUNCTION set_epis_admission
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels the admission of an episode and restores its previous dt_begin.
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_epis                  I_EPIS   Id of the episode to
    * @param      o_id_wl_screens         List of IDs of WL_MACHINEs that will issue the provided machine's calls
    * @param      O_ERROR an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   2009/10/23
    **********************************************************************************************/
    FUNCTION cancel_epis_admission
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sr_surgery_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN sr_surgery_time.id_sr_surgery_time%TYPE;

    /********************************************************************************************
    * create record in sr_pat_status table
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_episode               id_episode
    * @param      O_ERROR                 an error message, set when return=false    
    *
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Filipe Silva
    * @version 2.5.0.7.7
    * @since   2010/02/22
    **********************************************************************************************/

    FUNCTION create_sr_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_pat_status IN sr_pat_status.flg_pat_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Checks if a given episode has already been registered
    *
    * @param i_lang                ID language   
    * @param i_episode             ID of episode      
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.5.0.7.8
    * @since                       2010/03/24
    **********************************************************************************************/
    FUNCTION is_epis_registered
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get patient interventions
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional, institution and software IDs
    * @param i_id_patient              Patient ID
    * @param i_flg_status   Surgery status flag. Values : 'S' - Scheduled
    *                                                     'A' - All surgeries
    *
    * @param o_episodes                Episodes information cursor
    * @param o_error                   Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/09/15
    * @Notes                    ALERT-ALERT-124895
    ********************************************************************************************/
    FUNCTION get_pat_surg_episodes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_status IN VARCHAR2,
        o_episodes   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Match surgery episode status (update old one or delete the oldest)
    *
    * @param      I_LANG                  Language ID for translations
    * @param      I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param      I_ID_EPISODE_OLD        Old episode identifier to be updated/deleted
    * @param      I_ID_EPISODE_NEW        New episode identifier
    * @param      O_ERROR                 If an error accurs, this parameter will have information about the error    
    *
    * @RETURN                             false if errors occur, true otherwise
    *
    * @author                             antonio.neto
    * @version                            2.5.1.2.11
    * @since                              16-Dec-2011
    **********************************************************************************************/
    FUNCTION set_match_epis_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode_old IN episode.id_episode%TYPE,
        i_id_episode_new IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_episode   episode identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          2012/09/05 
    */
    FUNCTION get_desc_surg_proc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_desc_type      IN VARCHAR2,
        i_desc_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;
    /********************************************************************************************
    * Actualiza a sala prevista de realização de uma cirurgia na criação de um novo processo cirúrgico.
    *
    * @param i_lang             Id do idioma
    * @param i_schedule_sr      ID do agendamento
    * @param i_room             ID da sala prevista para a intervenção cirúrgica
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/11/28
    ********************************************************************************************/
    FUNCTION upd_surg_proc_preview_room
    (
        i_lang        IN language.id_language%TYPE,
        i_schedule_sr IN schedule_sr.id_schedule_sr%TYPE,
        i_room        IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -- Log initialization.    
    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);
    --
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_sr_dept      INTEGER;
    g_found        BOOLEAN;

    g_flg_status_temp     CONSTANT VARCHAR2(1) := 'T';
    g_flg_status_all      CONSTANT VARCHAR2(1) := 'T';
    g_flg_status_active   CONSTANT VARCHAR2(1) := 'A';
    g_flg_status_inactive CONSTANT VARCHAR2(1) := 'I';
    g_flg_pat_status_pend CONSTANT VARCHAR2(1) := 'A';
    g_rec_flg_agend       CONSTANT VARCHAR2(1) := 'A';
    g_rec_flg_naoagend    CONSTANT VARCHAR2(1) := 'T';
    g_cancel              CONSTANT VARCHAR2(1) := 'C';
    g_flg_yes             CONSTANT VARCHAR2(1) := 'Y';
    g_flg_no              CONSTANT VARCHAR2(1) := 'N';
	g_epis_finished       CONSTANT VARCHAR2(1) := 'F';
	
    g_interv_f CONSTANT VARCHAR2(1) := 'F';
    g_interv_e CONSTANT VARCHAR2(1) := 'E';
    g_interv_r CONSTANT VARCHAR2(1) := 'R';
    g_interv_c CONSTANT VARCHAR2(1) := 'C';
    g_interv_p CONSTANT VARCHAR2(1) := 'P';

    g_ambulatorio CONSTANT VARCHAR2(1) := 'A';

    g_schedule_state_not_sched CONSTANT VARCHAR2(1) := 'N';
    g_flg_urg_n                CONSTANT VARCHAR2(1) := 'N';
    g_flg_gender_m             CONSTANT patient.gender%TYPE := 'M';
    g_sr_software              CONSTANT software.id_software%TYPE := 2;
    g_soft_edis                CONSTANT software.id_software%TYPE := 8;

    g_catgsub_surg_resp CONSTANT category_sub.id_category_sub%TYPE := 1;

    g_intf_prof_catg CONSTANT category_sub.id_category_sub%TYPE := 11; -- Cirurgião

    --Tipos de episódio
    g_flg_unknown_temp CONSTANT epis_info.flg_unknown%TYPE := 'Y';
    g_flg_unknown_def  CONSTANT epis_info.flg_unknown%TYPE := 'N';

    g_visit_inactive CONSTANT visit.flg_status%TYPE := 'I';

    -- Advanced Input configurations
    g_all_institution institution.id_institution%TYPE;
    g_all_software    software.id_software%TYPE;
    g_advanced_input  advanced_input.id_advanced_input%TYPE;

    -- Keypad Date 
    g_multichoice_keypad advanced_input_field.type%TYPE;
    g_num_keypad         advanced_input_field.type%TYPE;
    g_date_keypad        advanced_input_field.type%TYPE;
    -- Tipos de episódio
    g_flg_ehr_n CONSTANT episode.flg_ehr%TYPE := 'N';
    g_flg_ehr_s CONSTANT episode.flg_ehr%TYPE := 'S';
    g_flg_ehr_e CONSTANT episode.flg_ehr%TYPE := 'E';

    g_surgi_approval CONSTANT approval_type.id_approval_type%TYPE := 11;

    g_sstd_flg_status_active CONSTANT sr_surgery_time_det.flg_status%TYPE := 'A';
    g_sst_flg_type_eb        CONSTANT sr_surgery_time.flg_type%TYPE := 'EB';

    g_flg_type_s CONSTANT department.flg_type%TYPE := 'S'; --sala bloco operatório

END pk_sr_visit;
/
