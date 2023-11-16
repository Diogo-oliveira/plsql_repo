/*-- Last Change Revision: $Rev: 2028987 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_surg_record AS

    FUNCTION get_surg_rec_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_prof            IN profissional,
        o_dt_sr_entry     OUT VARCHAR2,
        o_dt_room_entry   OUT VARCHAR2,
        o_dt_room_exit    OUT VARCHAR2,
        o_dt_sr_entry_d   OUT VARCHAR2,
        o_dt_room_entry_d OUT VARCHAR2,
        o_dt_room_exit_d  OUT VARCHAR2,
        o_interv          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter as intervenções agendadas para o Registo de Intervenção
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_EPISODE - ID do episódio 
                                         I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_DT_SR_ENTRY - Data de entrada no bloco operatório
                                    O_DT_ROOM_ENTRY - Data de entrada na sala operatória
                                        O_DT_ROOM_EXIT - Data de saída da sala operatória
                                        O_DT_SR_ENTRY_D - Data de entrada no bloco operatório (formato date)
                                        O_DT_ROOM_ENTRY_D - Data de entrada na sala operatória  (formato date)
                                        O_DT_ROOM_EXIT_D - Data de saída da sala operatória  (formato date)
                                O_INTERV - Array com as intervenções agendadas
                                    O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/06/08
      NOTAS: 
            
    *********************************************************************************/

    FUNCTION get_surg_rec_interv_end
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        o_dt_rcv_entry   OUT VARCHAR2,
        o_dt_rcv_exit    OUT VARCHAR2,
        o_dt_sr_exit     OUT VARCHAR2,
        o_dt_rcv_entry_d OUT VARCHAR2,
        o_dt_rcv_exit_d  OUT VARCHAR2,
        o_dt_sr_exit_d   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter as intervenções agendadas para o Registo de Intervenção
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_EPISODE - ID do episódio 
                                         I_PROF - ID do profissional, instituição e software
                           SAIDA:   O_DT_RCV_ENTRY - Data de entrada no Recobro
                                    O_DT_RCV_EXIT - Data de saída do Recobro
                                        O_DT_RCV_ENTRY_D - Data de entrada no Recobro (formato date)
                                        O_DT_RCV_EXIT_D - Data de saída do Recobro (formato date)
                                        O_DT_SR_EXIT_D - Data de saída do bloco (formato date)
                                    O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/06/08
      NOTAS: 
            
    *********************************************************************************/

    FUNCTION set_surg_rec_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_prof            IN profissional,
        i_dt_sr_entry     IN VARCHAR2,
        i_dt_room_entry   IN VARCHAR2,
        i_dt_room_exit    IN VARCHAR2,
        i_sr_intervention IN table_number,
        i_dt_interv_start IN table_varchar,
        i_dt_interv_end   IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Guarda as datas das intervenções agendadas no Registo de Intervenção
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_EPISODE - ID do episódio 
                                         I_PROF - ID do profissional, instituição e software
                                     I_DT_SR_ENTRY - Data de entrada no bloco operatório
                                     I_DT_ROOM_ENTRY - Data de entrada na sala operatória
                                         I_DT_ROOM_EXIT - Data de saída da sala operatória
                                         I_SR_INTERVENTION - Cursor com os IDs das intervenções
                                         I_DT_INTERV_START - Cursor com datas de início das intervenções
                                 I_DT_INTERV_END - Cursor com datas de fim das intervenções
                           SAIDA:   O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/06/08
      NOTAS:        
    *********************************************************************************/

    FUNCTION set_surg_rec_interv_end
    (
        i_lang         IN language.id_language%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_prof         IN profissional,
        i_dt_rcv_entry IN VARCHAR2,
        i_dt_rcv_exit  IN VARCHAR2,
        i_dt_sr_exit   IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Guarda as datas das intervenções agendadas no Registo de Intervenção
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_EPISODE - ID do episódio 
                                         I_PROF - ID do profissional, instituição e software
                                     I_DT_RCV_ENTRY - Data de entrada no Recobro
                                     I_DT_RCV_EXIT - Data de saída do Recobro
                                         I_DT_SR_EXIT - Data de saída do Bloco
                           SAIDA:   O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/06/08
      NOTAS:        
    *********************************************************************************/

    FUNCTION get_surg_rec_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN sr_surgery_rec_det.flg_type%TYPE,
        o_surg_rec OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter as descrições do Registo de Intervenção
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_EPISODE - ID do episódio 
                                         I_PROF - ID do profissional, instituição e software
                                         I_FLG_TYPE - Tipo de notas. Valores possíveis: R- Registo de intervenção
                                                                                    N - Notas
                           SAIDA:   O_SURG_REC - Array com as notas
                                    O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/06/08
      NOTAS: 
    *********************************************************************************/

    FUNCTION set_surg_rec_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_surgery_record IN sr_surgery_rec_det.id_surgery_record%TYPE,
        i_flg_type       IN sr_surgery_rec_det.flg_type%TYPE,
        i_notes          IN sr_surgery_rec_det.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Guarda as descrições do Registo de Intervenção
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_EPISODE - ID do episódio 
                                         I_PROF - ID do profissional, instituição e software
                                         I_SURGERY_RECORD - ID do registo de intervenção
                                         I_FLG_TYPE - Tipo de notas. Valores possíveis: R- Registo de intervenção
                                                                                    N - Notas
                                         I_NOTES - Registo de intervenção ou notas, de acordo com o FLG_TYPE
                           SAIDA:   O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/06/08
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_field_values_list
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_field   IN VARCHAR2,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter a lista de valores possíveis para a Resposta Verbal
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_EPISODE - ID do episódio 
                                         I_PROF - ID do profissional, instituição e software
                                         I_FIELD - Nome da coluna a preencher
                           SAIDA:   O_List - Array de valores possíveis para a Resposta Verbal
                                    O_ERROR - erro 
      
      CRIAÇÃO: RB 2006/06/10
      NOTAS:  O parâmetro I_FIELD deverá ser preenchido com o nome da coluna a preencher. Por exemplo:
                'SR_NURSE_REC.FLG_RESP_VERB''
    *********************************************************************************/

    FUNCTION set_surgery_time_def
    (
        i_lang           IN language.id_language%TYPE,
        i_software       IN software.id_software%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_flg_type       IN sr_surgery_time.flg_type%TYPE,
        i_rank           IN NUMBER,
        i_name           IN pk_translation.t_desc_translation,
        i_available      IN sr_surgery_time.flg_available%TYPE,
        i_flg_pat_status IN sr_surgery_time.flg_pat_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Criação/Alteração de uma definição de tempo operatório. A função irá verificar se existe para a instituição e software definidos já existe
                    um tempo operatório com o FLG_TYPE definido. Caso exista, actualiza a informação, caso contrário insere um novo registo.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_SOFTWARE - ID do software
                                         I_INSTITUTION - ID da insituição
                                         I_FLG_TYPE - Tipo do tempo operatório.
                             I_RANK - Rank para ordenações.
                             I_NAME - Nome para a língua definida.
                             I_AVAILABLE - Y-Disponível; N-Não disponívell
                             I_FLG_PAT_STATUS - Estado para onde deve mudar o paciente quando se introduz o tempo operatório, caso este exista.
                           SAIDA:   O_ERROR - erro 
      
      CRIAÇÃO: Rui Campos 2006/11/06
    *********************************************************************************/

    FUNCTION get_surgery_times
    (
        i_lang             IN language.id_language%TYPE,
        i_software         IN software.id_software%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtém os tempos operatórios para um dado episódio.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_SOFTWARE - ID do software
                                         I_INSTITUTION - ID da insituição
                             I_EPISODE - ID do episódio
                           SAIDA:    O_SURGERY_TIME_DEF - Cursor com as categorias de tempos operatórios definidos para o software e instituição definidos.
                             O_SURGERY_TIMES - Cursor com os tempos operatórios para o episódio definido.
                            O_ERROR - erro 
      
      CRIAÇÃO: Rui Campos 2006/11/07
    *********************************************************************************/

    FUNCTION get_surgery_time_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_sr_surgery_time  IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_surgery_time_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtém todos os tempos registados para uma categoria de tempo operatório.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_SOFTWARE - ID do software
                                         I_INSTITUTION - ID da insituição
                             I_SR_SURGERY_TIME - ID da categoria de tempo operatório
                             I_EPISODE - ID do episódio
                           SAIDA:    O_SURGERY_TIME_DET - Cursor com todos os tempos registados para a categoria definida.
                            O_ERROR - erro 
      
      CRIAÇÃO: Rui Campos 2006/11/07
    *********************************************************************************/

    FUNCTION set_surgery_time
    (
        i_lang                   IN language.id_language%TYPE,
        i_sr_surgery_time        IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_dt_surgery_time        IN VARCHAR2,
        i_prof                   IN profissional,
        i_test                   IN VARCHAR2,
        i_dt_reg                 IN VARCHAR2 DEFAULT NULL,
        i_transaction_id         IN VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_msg_result             OUT VARCHAR2,
        o_title                  OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_flg_refresh            OUT VARCHAR2,
        o_id_sr_surgery_time_det OUT sr_surgery_time_det.id_sr_surgery_time_det%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    -- telmo 16-12-2010. overloading necessario para uso do flash
    FUNCTION set_surgery_time
    (
        i_lang                   IN language.id_language%TYPE,
        i_sr_surgery_time        IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_dt_surgery_time        IN VARCHAR2,
        i_prof                   IN profissional,
        i_test                   IN VARCHAR2,
        i_dt_reg                 IN VARCHAR2 DEFAULT NULL,
        o_flg_show               OUT VARCHAR2,
        o_msg_result             OUT VARCHAR2,
        o_title                  OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_flg_refresh            OUT VARCHAR2,
        o_id_sr_surgery_time_det OUT sr_surgery_time_det.id_sr_surgery_time_det%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Regista um novo tempo operatório para uma categoria associado a um episódio (Caso exista um episódio activo será marcado como cancelado).
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                             I_SR_SURGERY_TIME - ID da categoria de tempo operatório
                             I_EPISODE - ID do episódio
                             I_DT_SURGERY_TIME - Data a registar.
                             I_PROF - Profissional responsável pela operação.
                             I_TEST - Permite apenas fazer a validação se o tempo operatório pode ser inserido, sem alterar dados. Valores possíveis:
                                            Y- Apenas faz validação.
                                                N- Execução normal da função.                    
                             I_DT_REG          data do registo dos tempos (migração),
                           SAIDA:   O_FLG_SHOW - Indica se existe uma mensagem para mostrar ao utilizador. Valores possíveis:
                                                    Y - Mostrar a mensagem
                                                    N - Não mostrar a mensagem
                            O_MSG_RESULT - Mensagem a apresentar
                            O_TITLE - Título da mensagem
                            O_BUTTON - Botões a apresentar. Combinação dos possíveis valores:
                                            N - Botão de não confirmação
                                            C - Botão de confirmação/lido 
                            O_ID_SR_SURGERY_TIME_DET - Created record ID
                            O_ERROR - erro 
      
      CRIAÇÃO: Rui Campos 2006/11/07
    *********************************************************************************/

    FUNCTION get_surg_time_default_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_surgery_time IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_date            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtém a data de registo default para uma categoria de tempos operatórios e um episódio. 
                    A data default é obtida do último registo activo e caso este não exista, a data de sistema.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                             I_PROF - Id do profissional, instituição e software 
                             I_SR_SURGERY_TIME - ID da categoria de tempo operatório
                             I_EPISODE - ID do episódio
                           SAIDA:   O_DATE - Data default a usar na criação de um novo registo.
                            O_ERROR - erro 
      
      CRIAÇÃO: Rui Campos 2006/11/07
    *********************************************************************************/

    /**************************************************************************
    * Update the surgical record                                              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/16                              *
    **************************************************************************/

    FUNCTION set_surg_process_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_status  IN sr_surgery_record.flg_sr_proc%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns the surgery estimated duration                                  *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    * @param i_duration                   estimated surgery duration          *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        2.5.7.7.1                               *
    * @since                          2010/04/06                              *
    **************************************************************************/

    FUNCTION get_surg_est_dur
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN schedule_sr.id_episode%TYPE,
        i_duration IN schedule_sr.duration%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_surgery_times_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_dt_end           IN VARCHAR2 DEFAULT NULL,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get information (entries) about surgeries done to patient's family members 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_current_episode    Current episode ID
    * @param   i_patient            Patient ID
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    *
    * @return  Information about entries (professional, record date, status, etc.)
    *
    * @author  ARIEL.MACHADO & FILIPE.SILVA
    * @version v2.6.0.4
    * @since   11/23/2010
    */
    FUNCTION tf_surgery_pat_family_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_current_episode IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_order           IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN pk_touch_option.t_coll_doc_area_register
        PIPELINED;

    /**
    * Get information (entries values) about surgeries done to patient's family members 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_patient            Patient ID
    *
    * @return  Information about data values saved in entries
    *
    * @author  ARIEL.MACHADO & FILIPE.SILVA
    * @version v2.6.0.4
    * @since   11/23/2010
    */
    FUNCTION tf_surgery_pat_family_val
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN pk_touch_option.t_coll_doc_area_val
        PIPELINED;

    /*******************************************************************************************************************************************
    * GET_SURGERY_TIME          Returns if current professional is an anesthesiologist and if he/she can edit an surgery/admission request
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             Episode Identifier
    * @param I_FLG_TYPE               Surgery time type
    * @param O_DT_SURGERY_TIME        Surgery time
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.1
    * @since                          23-Mai-2011
    *******************************************************************************************************************************************/
    FUNCTION get_surgery_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_type        IN sr_surgery_time.flg_type%TYPE,
        o_dt_surgery_time OUT sr_surgery_time_det.dt_surgery_time_det_tstz%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * ins_surgery_time_cfg            insert configuration into config_table
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_config              adequate id_config
    * @param i_inst_owner             inst_owner of id_config
    * @param i_id_sr_surgery_time     id_sr_surgery_time to onfigure ( will be id_record in CONFIG_TABLE )
    * @param i_rank                   sorting value
    * @param i_desc_sst               alternative description
    * @param i_flg_pat_status         Patient status that patient must assumed on SR_PAT_STATUS, when operative time for this category is filled.
    * @param i_show_config            boolean flag to show value of config used
    *
    * @raises                         generic error
    *
    * @author                         Sherlock
    * @version                        2.7.1
    * @since                          17-05-2017
    *******************************************************************************************************************************************/
    PROCEDURE ins_surgery_time_cfg
    (
        --        i_lang               IN language.id_language%TYPE,
        --        i_prof               IN profissional,
        i_id_config          IN NUMBER,
        i_inst_owner         IN NUMBER DEFAULT 0,
        i_id_sr_surgery_time IN NUMBER,
        i_rank               IN NUMBER,
        i_desc_sst           IN VARCHAR2,
        i_flg_pat_status     IN VARCHAR2
    );

    /*******************************************************************************************************************************************
    * ins_surgery_time                insert/update into sr_surgery_time
    *
    * @param i_id_sr_surgery_time     id given for record
    * @param i_flg_type               unique code. Works as identifier
    * @param i_flg_val_prev           Indicates if is necessary to fill the previous operative times. Values Y- Yes; N - No
    *
    * @raises                         generic error
    *
    * @author                         Sherlock
    * @version                        2.7.1
    * @since                          17-05-2017
    *******************************************************************************************************************************************/
    PROCEDURE set_surgery_time
    (
        i_id_sr_surgery_time IN NUMBER,
        i_flg_type           IN VARCHAR2,
        i_flg_val_prev       IN VARCHAR2
    );

    /*******************************************************************************************************************************************
    * Insert surgery times...
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION set_surgery_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_sr_surgery_time IN NUMBER,
        i_dt_surgery_time IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************
    * Get all surgery time detail as string
    *
    * @param i_lang       language idenfier
    * @param i_prof       profesional idenfier
    * @param i_episode    episode identifier
    *
    * @return VARCHAR2  return all surgery time detal as string
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-11-15
    ************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    /*************************************************************************
    * Get all surgery time detail as string
    *
    * @param i_lang       language idenfier
    * @param i_prof       profesional idenfier
    * @param i_epis       episode idenfier
    *
    * @return VARCHAR2  return all surgery time detal as string
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-11-15
    ************************************************************************/
    FUNCTION get_surgery_time_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get all surgery record as cursor
    *
    * @param i_lang             language idenfier
    * @param i_prof             profesional idenfier
    * @param i_epis             episode identifier list
    * @param i_patient          patient identifier
    * @param o_surgery_record   all surgery record
    * @param o_error            t_error_out type error
    *
    * @return cursor_type
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-11-15
    **********************************************************************************************/
    FUNCTION get_surgery_record_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_surgery_record OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get surgery record brief description as cursor
    *
    * @param i_lang                    language idenfier
    * @param i_prof                    profesional idenfier
    * @param i_epis                    episode identifiers list
    * @param i_patient                 patient identifier
    * @param o_brief_surgery_record    all surgery records
    * @param o_error                   t_error_out type error
    *
    * @return cursor_type
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-12-15
    **********************************************************************************************/
    FUNCTION get_sr_brief_det
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis                 IN table_number,
        i_patient              IN patient.id_patient%TYPE,
        o_brief_surgery_record OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get surgery record brief description
    *
    * @param i_lang                    language idenfier
    * @param i_prof                    profesional idenfier
    * @param i_episode                 episode idenfier
    * @param i_patient                 patient identifier
    *
    * @return CLOB
    *
    * @author             Kelsey Lai
    * @version            2.7.2.6
    * @since              2018-02-23
    **********************************************************************************************/
    FUNCTION get_sr_brief_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN CLOB;
    g_exception EXCEPTION;

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_sr_dept      INTEGER;
    g_found        BOOLEAN;

    g_interv_req  CONSTANT VARCHAR2(1) := 'R';
    g_interv_part CONSTANT VARCHAR2(1) := 'E';
    g_interv_exec CONSTANT VARCHAR2(1) := 'F';
    g_interv_can  CONSTANT VARCHAR2(1) := 'C';

    g_value_y          CONSTANT VARCHAR2(1) := 'Y';
    g_value_n          CONSTANT VARCHAR2(1) := 'N';
    g_status_available CONSTANT VARCHAR2(1) := 'A';
    g_status_cancel    CONSTANT VARCHAR2(1) := 'C';

    -- Valor de ID_INSTITUTION que representa todas as instituições
    g_all_institutions CONSTANT NUMBER := 0;

    -- FLG_TYPE value that corresponds to the beginning of the surgery
    g_type_surg_begin CONSTANT sr_surgery_time.flg_type%TYPE := 'IC';
    -- FLG_TYPE value that corresponds to the end of the surgery
    g_type_surg_end CONSTANT sr_surgery_time.flg_type%TYPE := 'FC';
    --Start of anesthesia
    g_type_anest_start CONSTANT sr_surgery_time.flg_type%TYPE := 'IA';
    --Patient entrance to the OR suite
    g_type_patient_ent CONSTANT sr_surgery_time.flg_type%TYPE := 'EB';
    --Patient entrance to the Operating room
    g_type_patient_ent_room CONSTANT sr_surgery_time.flg_type%TYPE := 'ES';

    -- FLG_STATUS value on the SR_EPIS_INTERV that corresponds to 'In Execution'
    g_interv_status_execution CONSTANT sr_epis_interv.flg_status%TYPE := 'E';
    -- FLG_STATUS value on the SR_EPIS_INTERV that corresponds to 'Requisition'
    g_interv_status_requisition CONSTANT sr_epis_interv.flg_status%TYPE := 'R';
    -- FLG_STATUS value on the SR_EPIS_INTERV that corresponds to 'Requisition'
    g_interv_status_finished CONSTANT sr_epis_interv.flg_status%TYPE := 'F';

    g_flg_type_rec CONSTANT epis_prof_rec.flg_type%TYPE := 'R';

    g_surgery_process_type ti_log.flg_type%TYPE := 'SR';

    g_sr_surgery_time_det_status CONSTANT sys_domain.code_domain%TYPE := 'SR_SURGERY_TIME_DET.FLG_STATUS';

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    k_sr_time_cfg_table CONSTANT VARCHAR2(0050 CHAR) := 'SR_SURGERY_TIME';

    g_colon    CONSTANT VARCHAR2(2 CHAR) := ': ';
    g_comma    CONSTANT VARCHAR2(2 CHAR) := ', ';
    g_new_line CONSTANT VARCHAR2(2 CHAR) := chr(10);
END pk_sr_surg_record;
/
