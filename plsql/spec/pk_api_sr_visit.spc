/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_sr_visit IS

    TYPE sr_new_schedule_struct IS RECORD(
        id_wait_list       NUMBER(24), --Identificador da inscrição na lista de espera
        id_schedule        NUMBER(24), --Identificador único do agendamento
        dt_schedule_tstz   TIMESTAMP WITH LOCAL TIME ZONE, --Data de intervenção cirúrgica
        interv_type        VARCHAR2(100), --Tipo: efectivo / suplente
        id_room            NUMBER(24), --Sala
        flg_surg_type      VARCHAR2(10), --Tipo cirurgia: limpa, contaminada, suja, ...
        duration           NUMBER(6), --Duração prevista
        id_prof_resp       NUMBER(24), --Cirurgião
        id_prof_req        NUMBER(24), --Responsável pelo agendamento
        id_diagnosis       NUMBER(12), --Diagnóstico
        id_patient         NUMBER(24), --Identificador único do utente
        flg_blood_req      VARCHAR2(1), --Indicação de existência de requisição de sangue / hemoderivados
        id_dep_clin_serv   NUMBER(24),
        num_episode_prev   VARCHAR2(40), --SONHO previous episode referring to -- ALERT-31101 
        cod_module         VARCHAR2(6), -- module type (INT,CON,URG) -- ALERT-31101 
        id_external_sys    NUMBER(12), -- external system unique identifier
        dt_sr_surgery_tstz TIMESTAMP WITH LOCAL TIME ZONE --Date for Surgical episode
        );

    TYPE sr_cancel_schedule_struct IS RECORD(
        id_episode NUMBER(24), --identificação do episódio
        --        dt_cancel        DATE, --Data / hora de cancelamento
        dt_cancel_tstz   TIMESTAMP WITH LOCAL TIME ZONE, --Data / hora de cancelamento
        id_cancel_reason NUMBER(24), --Código de razão de cancelamento
        id_speciality    NUMBER(12), --Especialidade
        id_prof_cancel   NUMBER(24) --Responsável pelo registo
        );

    /******************************************************************************
       OBJECTIVO:   Cria todos os registos necessários ao início do planeamento de uma nova cirurgia, ainda antes
           de existir um agendamento, diagnóstico base e intervenção a realizar definidos.
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                             I_PROF - ID do profissional, instituição e software
                             I_REC - Array de valores a utilizar para criar os registos
                             I_ID_EPISODE_EXT - ID do episódio externo
           Saida:   O_EPISODE - ID do episódio criado
                        O_VISIT - ID da visita criada
                        O_ERROR - erro 
     
      CRIAÇÃO: RB 2006/11/30 
      NOTAS: 
    *********************************************************************************/
    FUNCTION interface_create_all_surgery
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_rec             IN pk_api_sr_visit.sr_new_schedule_struct,
        i_id_episode_ext  IN VARCHAR2,
        i_id_prev_episode IN episode.id_prev_episode%TYPE DEFAULT NULL,
        io_episode        IN OUT episode.id_episode%TYPE,
        io_visit          IN OUT visit.id_visit%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Cancela o agendamento de uma cirurgia
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                         I_PROF - ID do profissional, instituição e software
                                         I_REC - Array de valores a utilizar para criar os registos
           Saida:   O_ERROR - erro 
     
      CRIAÇÃO: RB 2006/11/30 
      NOTAS: 
    *********************************************************************************/
    FUNCTION interface_cancel_surgery
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_rec   IN pk_api_sr_visit.sr_cancel_schedule_struct,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Insere as intervenções cirúrgicas agendadas para o episódio.
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                         I_PROF - ID do profissional, instituição e software
                                        I_EPISODE - ID do episódio
                                        I_SR_INTERVENTION - ID da intervenção cirúrgica
                         I_PROF_REQ - ID do profissional requisitado                    
           Saida:   O_ERROR - erro 
     
      CRIAÇÃO: RB 2006/11/30 
      NOTAS: 
    *********************************************************************************/
    FUNCTION interface_ins_epis_surg
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_sr_intervention   IN intervention.id_intervention%TYPE,
        i_prof_req          IN professional.id_professional%TYPE,
        i_flg_type          IN sr_epis_interv.flg_type%TYPE DEFAULT 'P',
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        o_sr_epis_interv    OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
        
    ) RETURN BOOLEAN;

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

    /**************************************************************************
    * gets all scheduled oris episodes for a specific time interval           *
    *                                                                         *
    *@param  i_lang                preferred language id                      *
    *@param  i_prof                Professional struture                      *
    *@param  i_dt_begin            Begin date interval                        *
    *@param  i_dt_end              End date interval                          *
    *                                                                         *
    *@return t_tbl_sr_scheduled_episodes collection                           *
    *                                                                         *  
    * @author                          Gustavo Serrano                        *
    * @version                         v2.6.0.3                               *   
    * @since                           2010/06/02                             *    
    **************************************************************************/
    FUNCTION tf_scheduled_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_sr_scheduled_episodes;

    /**************************************************************************
    * inserts in scheduled room and updates epis_info                         *
    *                                                                         *
    *@param  i_lang                 IN  preferred language id                 *
    *@param  i_episode              IN Episode ID                             *
    *@param  i_dt_schedule_tstz     IN Room schedule date                     *
    *@param  i_id_room              IN Room ID                                *
    *@param  i_rec_flg              IN Room status                            *
    *@param  i_id_schedule          IN Schedule ID                            *
    *                                                                         *
    *@param      o_error            OUT erro                                  *
    *                                                                         *
    *@return t_tbl_sr_scheduled_episodes collection                           *
    *                                                                         *  
    * @author                          Sérgio Dias                            *
    * @version                         v2.6.0.3                               *   
    * @since                           2010/08/20                             *    
    **************************************************************************/
    FUNCTION schedule_room
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_schedule_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_room          IN room.id_room%TYPE,
        i_rec_flg          IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Actualiza a data prevista de realização de uma cirurgia na criação de um novo processo cirúrgico.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_schedule_sr      ID do agendamento
    * @param i_dt               Data prevista da realização da cirurgia
    * @param i_dep_clin_serv    New dep_clin_serv
    * @param i_duration         New duration in minutes
    * @param i_diagnosis        New diagnosis
    * @param i_room             New cirurgic room
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Paulo Teixeira
    * @since                    2013/09/24
    ********************************************************************************************/
    FUNCTION interface_set_sr_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_schedule_sr   IN schedule_sr.id_schedule_sr%TYPE,
        i_dt            IN schedule_sr.dt_target_tstz%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_duration      IN schedule_sr.duration%TYPE,
        i_diagnosis     IN schedule_sr.id_diagnosis%TYPE,
        i_room          IN room.id_room%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Insert surgery times...
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_set_surgery_dates
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_sr_surgery_time IN NUMBER,
        i_dt_surgery_time IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Insert the team associated to surgery record
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_set_team
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_tbl_prof IN table_number,
        i_tbl_catg IN table_number,
        o_id_team  OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Insert the intervention and the associated team
    *
    * @param i_lang                 ID lang
    * @param i_prof                 ID prof
    * @param i_episode              ID episode
    * @param i_sr_intervention      ID intervention (intervention.id_content)
    * @param i_intervention_type    Intervention type (intervention.flg_type - 'S' or 'P')
    * @param i_id_epis_diagnosis    ID epis_diagnosis 
    * @param i_prof_team            ID_prof_team
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION interface_ins_bulk_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_intervention      IN table_varchar,
        i_intervention_type IN table_varchar,
        i_id_epis_diagnosis IN table_number DEFAULT NULL,
        i_prof_team         IN table_number DEFAULT NULL,
        o_sr_epis_interv    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION interface_create_surgery
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_prev_episode    IN episode.id_prev_episode%TYPE,
        i_id_episode_ext     IN VARCHAR2,
        i_id_wait_list       IN NUMBER,
        i_id_schedule        IN NUMBER,
        i_dt_schedule_tstz   IN VARCHAR2,
        i_interv_type        IN VARCHAR2,
        i_id_room            IN NUMBER,
        i_flg_surg_type      IN VARCHAR2,
        i_duration           IN NUMBER,
        i_id_prof_resp       IN NUMBER,
        i_id_prof_req        IN NUMBER,
        i_id_diagnosis       IN NUMBER,
        i_cod_icd_diagnosis  IN VARCHAR2,
        i_id_patient         IN NUMBER,
        i_flg_blood_req      IN VARCHAR2,
        i_id_dep_clin_serv   IN NUMBER,
        i_num_episode_prev   IN VARCHAR2,
        i_cod_module         IN VARCHAR2,
        i_id_external_sys    IN NUMBER,
        i_dt_sr_surgery_tstz IN VARCHAR2,
        io_episode           IN OUT episode.id_episode%TYPE,
        io_visit             IN OUT visit.id_visit%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(32000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Stores the owner name. */
    g_package_owner VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';
    --
    g_inp_epis_type            CONSTANT PLS_INTEGER := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', 0, 0);
    g_flg_urg_n                CONSTANT VARCHAR2(1) := 'N';
    g_schedule_state_not_sched CONSTANT VARCHAR2(1) := 'N';
    --
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    --
    g_cancel  CONSTANT VARCHAR2(1) := 'C';
    g_flg_yes CONSTANT VARCHAR2(1) := 'Y';
    g_flg_no  CONSTANT VARCHAR2(1) := 'N';
    g_found BOOLEAN;
    --
    g_interv_f CONSTANT VARCHAR2(1) := 'F';
    g_interv_e CONSTANT VARCHAR2(1) := 'E';
    g_interv_r CONSTANT VARCHAR2(1) := 'R';
    g_interv_c CONSTANT VARCHAR2(1) := 'C';
    g_interv_p CONSTANT VARCHAR2(1) := 'P';
    --
    g_rec_flg_agend    CONSTANT VARCHAR2(1) := 'A';
    g_rec_flg_naoagend CONSTANT VARCHAR2(1) := 'T';
    --
    g_flg_status_active   CONSTANT VARCHAR2(1) := 'A';
    g_flg_status_inactive CONSTANT VARCHAR2(1) := 'I';
    g_flg_pat_status_pend CONSTANT VARCHAR2(1) := 'A';
    --Tipos de episódio
    g_flg_unknown_temp CONSTANT epis_info.flg_unknown%TYPE := 'Y';
    g_flg_unknown_def  CONSTANT epis_info.flg_unknown%TYPE := 'N';
    --
    g_catgsub_surg_resp CONSTANT category_sub.id_category_sub%TYPE := 1;
    g_intf_prof_catg    CONSTANT category_sub.id_category_sub%TYPE := 11; -- Cirurgião
    -- Tipos de episódio
    g_flg_ehr_n CONSTANT episode.flg_ehr%TYPE := 'N';
    -- exception
    g_exception EXCEPTION;
END pk_api_sr_visit;
/
