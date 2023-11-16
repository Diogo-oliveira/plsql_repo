/*-- Last Change Revision: $Rev: 2053266 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-15 16:10:41 +0000 (qui, 15 dez 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_planning AS

    /********************************************************************************************
    * Obter as opções disponíveis no multichoice da Cirurgia Proposta.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             IDs referring to professional, institution and software
    * @param i_origin           origin of the call (from which mchoice option it was invoked)
    * @param o_options          Cursor com as opções
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/12/12
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     ALERT-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/
    FUNCTION get_surg_procedures_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_origin  IN VARCHAR2,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Activates permanently temporary surgical procedures 
    *
    * @param i_lang             Language ID
    * @param i_episode          Episode ID
    * @param i_sr_epis_interv   ID from surgical procedures table 
    * @param i_sr_intervention  ID 
    * @param i_prof             Professional ID
    * @param i_id_cdr_call      Rule event identifier.
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   RB 
    * @since                    2006/10/09
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     ALERT-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION set_conf_epis_surg_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_prof            IN profissional,
        i_id_cdr_call     IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Cancela a prescrição de um procedimento cirurgico para um episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_sr_epis_interv   Procedure's id, which may refer to an (un)coded one
    * @param i_prof             ID do profissional, instituição e software
    * @param i_sr_cancel_reason ID do motivo de cancelamento do procedimento cirúrgico.
    * @param i_notes            Notas de cancelamento
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2005/10/27
    * 
    * @author    Pedro Santos
    * @version   2.4.3.x
    * @since     2009/03/03
    * reason     ALERT-16467  inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION cancel_epis_surg_proc
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_sr_epis_interv   IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_prof             IN profissional,
        i_sr_cancel_reason IN sr_epis_interv.id_sr_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_posit_list
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_flg_status IN table_varchar DEFAULT NULL,
        o_posit      OUT pk_types.cursor_type,
        o_status     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_posit_list_det
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_prof      IN profissional,
        o_posit     OUT pk_types.cursor_type,
        o_status    OUT pk_types.cursor_type,
        o_posit_rel OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reserv_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_sr_equip      IN sr_equip.id_sr_equip%TYPE,
        i_type          IN sr_equip.flg_type%TYPE DEFAULT 'R',
        i_search        IN VARCHAR2,
        o_reserv        OUT pk_types.cursor_type,
        o_icon_y        OUT VARCHAR2,
        o_icon_pesquisa OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_period_list
    (
        i_lang     IN language.id_language%TYPE,
        i_id_equip IN sr_equip.id_sr_equip%TYPE,
        o_period   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reserv_req_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN sr_reserv_req.flg_type%TYPE DEFAULT 'R',
        o_req     OUT pk_types.cursor_type,
        o_icon_y  OUT VARCHAR2,
        o_icon_n  OUT VARCHAR2,
        o_icon_c  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_reserv_req_det
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_protocols       IN protocols.id_protocols%TYPE,
        i_prof            IN profissional,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_reserv          IN table_number,
        i_flg_status_new  IN table_varchar,
        i_flg_status_old  IN table_varchar,
        i_surg_period     IN table_number,
        i_qty_req         IN table_number,
        i_type            IN sr_reserv_req.flg_type%TYPE DEFAULT 'R',
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_reserv_req_status
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_reserv_req     IN table_number,
        i_flg_status_new IN table_varchar,
        i_flg_status_old IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_reserv_req
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_sr_reserv_req IN sr_reserv_req.id_sr_reserv_req%TYPE,
        i_prof          IN profissional,
        i_notes_cancel  IN sr_reserv_req.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_reserv_req_det
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_protocols       IN protocols.id_protocols%TYPE,
        i_prof            IN profissional,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_reserv          IN table_number,
        i_flg_status_new  IN table_varchar,
        i_flg_status_old  IN table_varchar,
        i_surg_period     IN table_number,
        i_qty_req         IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_reserve_grid_task
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obter as intervenções cirurgicas mais frequentes para um departamento clínico
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          Id do episódio
    * @param i_patient          ID do paciente
    * @param i_dep_clin_serv    ID do departamento clínico
    * @param i_search           Texto a pesquisar
    * @param i_flg_freq         Y - more frequent texts; N - otherwise
    *
    * @param o_list             Lista das intervenções mais frequentes
    * @param o_list_sel         Lista das intervenções cirúrgicas seleccionadas
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/09
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION get_freq_interv_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_search        IN VARCHAR2,
        i_flg_freq      IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_list_sel      OUT pk_types.cursor_type,
        o_status        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obter as intervenções cirurgicas mais frequentes para um departamento clínico
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          Id do episódio
    * @param i_patient          ID do paciente
    * @param i_dep_clin_serv    ID do departamento clínico
    * @param i_search           Texto a pesquisar    
    *
    * @param o_list             Lista das intervenções mais frequentes
    * @param o_list_sel         Lista das intervenções cirúrgicas seleccionadas
    * @param o_status           Array de icones a mostrar para os vários estados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *     
    * @author    Sofia Mendes
    * @version   2.6.1
    * @since     19-Mai-2011   
    *********************************************************************************************/
    FUNCTION get_freq_interv_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_search        IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_list_sel      OUT pk_types.cursor_type,
        o_status        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Obter as intervenções seleccionadas para um episódio
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                    I_PROF - ID do profissional, instituição e software
                                              I_EPISODE - ID do episódio actual
                           SAIDA:   O_LIST - Lista das intervenções seleccionadas para o episódio
                                        O_ERROR - erro
    
      CRIAÇÃO: Rui Campos 2006/12/11
      NOTAS:
    *********************************************************************************/
    /********************************************************************************************
    * Prescrever temporariamente as intervenções cirúrgicas para um episódio. Só ao fazer OK no
    *   ecrã é que elas ficarão activas permanentemente.
    *
    * @param i_lang                 Id do idioma
    * @param i_episode              Id do episódio
    * @param i_episode_context      ID do episódio de contexto, onde a informação poderá ser visível
    * @param i_sr_intervention      ID da intervenção
    * @param i_prof                 ID do profissional, instituição e software
    * @param o_error                Mensagem de erro
    *
    * @return                       TRUE/FALSE
    *
    * @author                       Rui Batista
    * @since                        2006/10/10
    *     
    * @author    Pedro Santos
    * @version   2.4.3.x
    * @since     2009/01/15
    * reason     Alert-1905 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION set_epis_surg_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_sr_intervention IN intervention.id_intervention%TYPE,
        i_prof            IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Prescrever temporariamente as intervenções cirúrgicas para um episódio. Só ao fazer OK no
    *   ecrã é que elas ficarão activas permanentemente.
    *
    * @param i_lang                 Id do idioma
    * @param i_episode              Id do episódio
    * @param i_episode_context      ID do episódio de contexto, onde a informação poderá ser visível
    * @param i_sr_intervention      Lista de id's da intervenção
    * @param i_prof                 ID do profissional, instituição e software
    * @param o_error                Mensagem de erro
    *
    * @return                       boolean
    *
    * @author                       Gustavo Serrano
    * @since                        2009/09/28
    *
    *********************************************************************************************/

    FUNCTION set_epis_surg_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_sr_intervention IN table_number,
        i_prof            IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Mostra detalhe de cancelamento de uma reserva
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_reserv_req       ID da reserva
    *
    * @param o_reserv           Descrição da reserva cancelada
    * @param o_notes            Notas de cancelamento
    * @param o_prof_cancel      ID do profissional que cancelou
    * @param o_dt_cancel        Data de cancelamento
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/24
    **********************************************************************************************/
    FUNCTION get_reserv_cancel_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_reserv_req  IN sr_reserv_req.id_sr_reserv_req%TYPE,
        o_reserv      OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_prof_cancel OUT VARCHAR2,
        o_dt_cancel   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Shows Reserve Detail
    *
    * @param i_lang             Id of language
    * @param i_prof             ID of professional, institution and software
    * @param i_id_sr_reserv_req ID of reserve
    * @param i_flg_screen       Flag of Detail type (D-detail; H-history)
    * @param o_reserv_req       Cursor with the data
    * @param o_error            Error Message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   António Neto
    * @since                    2011/05/11
    **********************************************************************************************/
    FUNCTION get_reserv_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sr_reserv_req IN sr_reserv_req.id_sr_reserv_req%TYPE,
        i_flg_screen       IN VARCHAR2,
        o_reserv_req       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:  Mostra detalhe de cancelamento de uma reserva
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                           I_PROF - ID do profissional, instituição e software
                                           I_RESERV_REQ - ID da reserva
           Saida:  O_RESERV -  Descrição da reserva cancelada
                      O_NOTES - Notas de cancelamento
                      O_PROF_CANCEL - ID do profissional que cancelou
                      O_DT_CANCEL - Data de cancelamento
                O_ERROR - erro
    
      CRIAÇÃO: RB 2006/10/24
      NOTAS:
    *********************************************************************************/

    FUNCTION get_posit_cancel_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_posit_req   IN sr_posit_req.id_sr_posit_req%TYPE,
        o_posit       OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_prof_cancel OUT VARCHAR2,
        o_dt_cancel   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:  Mostra detalhe de cancelamento de um posicionamento
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                           I_PROF - ID do profissional, instituição e software
                                           I_POSIT_REQ - ID da requisição do posicionamento
           Saida:  O_POSIT -  Descrição do posicionamento cancelado
                      O_NOTES - Notas de cancelamento
                      O_PROF_CANCEL - ID do profissional que cancelou
                      O_DT_CANCEL - Data de cancelamento
                O_ERROR - erro
    
      CRIAÇÃO: RB 2006/10/24
      NOTAS:
    *********************************************************************************/

    /********************************************************************************************
    * Get surgical procedures summary page
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_episode          Id Episode
    *
    * @param o_interv           Data cursor
    * @param o_labels           Labels cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/27
    *     
    * @author    Pedro Santos
    * @version   2.5 sp3
    * @since     2009/03/03
    * reason     Alert-16467 inserting uncoded surgical procedures (through free text)
    *********************************************************************************************/

    FUNCTION get_summ_interv
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        o_interv                    OUT NOCOPY pk_types.cursor_type,
        o_labels                    OUT NOCOPY pk_types.cursor_type,
        o_interv_supplies           OUT NOCOPY pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:  Mostra a descrição da cirurgia proposta na página resumo da cirurgia proposta
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                           I_PROF - ID do profissional, instituição e software
                                           I_EPISODE - ID do episódio
           Saida:  O_INTERV - Array com a lista de intervenções
                O_SURG -  Array com a descrição das cirurgias
                O_ERROR - erro
    
      CRIAÇÃO: RB 2006/10/27
      NOTAS:
    *********************************************************************************/

    /**************************************************************************
    * Returns the consent information for a specific ORIS episode             *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    * @param i_dep_clin_serv          Dep_clin_serv ID                        *
    *                                                                         *
    * @return                         Returns consent info cursor             *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/08/28                              *
    **************************************************************************/
    FUNCTION get_epis_consent
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_consent       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * Returns the consent options to fill questions                               *
    *                                                                             *
    * @param i_lang                   Language ID                                 *
    * @param i_prof                   Profissional ID                             *
    * @param i_patient                Patient Id                                  *
    * @param i_dep_clin_serv          Dep_clin_serv ID                            *
    *                                                                             *
    * @return o_doctor_sign_cst       Returns doctor sign options cursor          *
    * @return o_doctor_cst_list       Returns doctor list for sign cursor         *
    * @return o_pat_sign_cst          Returns patient sign options cursor         *
    * @return o_pat_family_rel        Returns family relation cursor              *
    * @return o_cst_dest              Returns consent destination options cursor  *
    *                                                                             *
    * @author                         Gustavo Serrano                             *
    * @version                        1.0                                         *
    * @since                          2009/08/28                                  *
    ******************************************************************************/
    FUNCTION get_consent_input_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_doctor_sign_cst OUT pk_types.cursor_type,
        o_doctor_cst_list OUT pk_types.cursor_type,
        o_pat_sign_cst    OUT pk_types.cursor_type,
        o_pat_family_rel  OUT pk_types.cursor_type,
        o_cst_dest        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Saves the consent information for a specific ORIS episode               *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    * @param i_flg_physician_sign     Flag physician sign                     *
    * @param i_id_prof_resp           Professional responsible                *
    * @param i_flg_patient_sign       Flag patient sign                       *
    * @param i_patient_rep_name       Patient's representative person name    *
    * @param i_id_family_rel          Patient's representative person relation*
    * @param i_flg_consent_dest       Destination of consent                  *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/08/28                              *
    **************************************************************************/
    FUNCTION set_epis_consent
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_physician_sign IN sr_consent.flg_physician_sign%TYPE,
        i_id_prof_resp       IN sr_consent.id_prof_resp%TYPE,
        i_flg_patient_sign   IN sr_consent.flg_patient_sign%TYPE,
        i_patient_rep_name   IN sr_consent.patient_rep_name%TYPE,
        i_id_family_rel      IN sr_consent.id_family_relationship%TYPE,
        i_flg_consent_dest   IN sr_consent.flg_consent_dest%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get surgery detail for a specific episode                               *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    * @param o_epis_doc_register      array with the detail info register     *
    * @param o_epis_document_val      array with detail of documentation      *
    * @param o_surgical_episode       cursor with information of cancel       *
    *                                 surgical episode                        *
    * @param o_error                  Error message                           *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @since                          2009/09/14                              *
    **************************************************************************/

    FUNCTION get_surgery_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_cancel_surg_epis  OUT pk_types.cursor_type,
        o_null_surg_epis    OUT pk_types.cursor_type,
        o_surg_epis         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
        
    ) RETURN BOOLEAN;

    /*********************************************************************************
    * check if the data record meet or not the requirements for the                  *
    * surgical procedures                                                            *
    *                                                                                *
    * @param i_lang                   Language ID                                    *
    * @param i_prof                   Profissional ID                                *
    * @param i_list_in                Internals names list                           *
    * @param i_episode                ORIS episode                                   *
    *                                                                                * 
    * @param o_flg_show              (Y) return alert message/(N)no return alert msg *                                      
    * @param o_msg                    message                                        *
    * @param o_msg_title              message title                                  *
    * @param o_button                                                                *
    * @param o_error                  error message                                  *
    *                                                                                *               
    * @return                         Returns boolean                                *
    *                                                                                *
    * @author                         Filipe Silva                                   *
    * @version                        1.0                                            *
    * @since                          2009/09/09                                     *
    *********************************************************************************/
    FUNCTION check_surgery_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_group      IN sr_surgery_validation.flg_group%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_internal_names OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancels the consent information for a specific ORIS episode             *
    *                                                                         *
    * @param i_lang                   Language ID                             *
    * @param i_prof                   Profissional ID                         *
    * @param i_episode                ORIS episode                            *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/21                              *
    **************************************************************************/
    FUNCTION cancel_consent_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Compare if the timestamp is more recent of the surgical date. In case the timestamp is more recent
    * then the requisition date is used else is the surgical date minus the time margin (defined in sys_config)
    *
    * @param i_lang             id_language
    * @param i_prof             ID professional, institution e software
    * @param i_episode          id_episode
    * @param i_dt_req_tstz      requisition's date
    *
    * @param o_surg_date_is_null return (Y) if the surgery_date is null otherwise (N) 
    *
    * @return                   TIMESTAMP
    *
    * @author                   Filipe Silva
    * @Version                  2.6.0.4
    * @since                    2010/11/18
       ********************************************************************************************/

    FUNCTION get_surg_dt_margin
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_dt_req_tstz IN sr_reserv_req.dt_req_tstz%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE;
    /********************************************************************************************
    * Compare if the timestamp is more recent of the surgical date. In case the timestamp is more recent
    * then the requisition date is used else is the surgical date minus the time margin (defined in sys_config)
    *
    * @param i_lang             id_language
    * @param i_prof             ID professional, institution e software
    * @param i_episode          id_episode
    * @param i_dt_req_tstz      requisition's date
    *
    * @param i_surg_date_is_null return (Y) if the surgery_date is null otherwise (N)        
    *
    * @return                   TIMESTAMP
    *
    * @author                   Filipe Silva
    * @Version                  2.5.0.7.7
    * @since                    2010/03/01
       ********************************************************************************************/
    FUNCTION get_surg_dt_margin
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_dt_req_tstz       IN sr_reserv_req.dt_req_tstz%TYPE,
        o_surg_date_is_null OUT VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /********************************************************************************************
    * Saves an interventiont description without committing
    *
    * @param i_lang                     Language ID
    * @param i_episode                  Episode ID
    * @param i_episode_context          Context episode ID
    * @param i_sr_epis_interv           Refers to the surgical procedure it can thus refer to either an coded or uncoded one
    * @param i_prof                     Professional object
    * @param i_notes                    Intervention notes
    *
    * @param o_id_sr_epis_interv_desc   Created record ID
    * @param o_error                    Returned error
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sergio Dias
    * @since                    2010/09/14
    *********************************************************************************************/

    FUNCTION set_surg_proc_desc_no_commit
    (
        i_lang                   IN language.id_language%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_episode_context        IN episode.id_episode%TYPE,
        i_sr_epis_interv         IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_prof                   IN profissional,
        i_notes                  IN VARCHAR2,
        i_dt_interv_desc         IN VARCHAR2 DEFAULT NULL,
        o_id_sr_epis_interv_desc OUT sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Register one or more uncoded surgical procedures inserted through text field without committing
    *
    * @param i_lang                Language ID
    * @param i_id_episode          Episode ID
    * @param i_id_episode_context  Episode ID Context where data may be available
    * @param i_name_interv         Array with all the uncoded surgical procedures to be inserted
    * @param i_prof                Professional ID, Institution ID AND Software ID
    * @param i_id_patient          Patient ID
    * @param i_notes               Notes
    * @param i_dt_interv_start     Intervention start date
    * @param i_dt_interv_end       Intervention end date
    * @param i_dt_req              Intervention request date
    * @param i_id_epis_diagnosis   Epis diagnosis ID
    * @param o_id_sr_epis_interv   Created record ID
    * @param o_error            Error Message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Pedro Santos
    * @version                  2.5 sp3
    * @since                    2009/03/03
    ********************************************************************************************/

    FUNCTION set_epis_surg_unc_no_commit
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_episode_context      IN episode.id_episode%TYPE,
        i_name_interv             IN table_varchar,
        i_prof                    IN profissional,
        i_id_patient              IN patient.id_patient%TYPE,
        i_notes                   IN VARCHAR2,
        i_dt_interv_start         IN VARCHAR2 DEFAULT NULL,
        i_dt_interv_end           IN VARCHAR2 DEFAULT NULL,
        i_dt_req                  IN VARCHAR2,
        i_id_epis_diagnosis       IN sr_epis_interv.id_epis_diagnosis%TYPE,
        i_flg_type                IN sr_epis_interv.flg_type%TYPE,
        i_laterality              IN sr_epis_interv.laterality%TYPE,
        i_surgical_site           IN sr_epis_interv.surgical_site%TYPE,
        i_id_not_order_reason     IN not_order_reason.id_not_order_reason%TYPE,
        i_clinical_question       IN table_number DEFAULT NULL,
        i_response                IN table_varchar DEFAULT NULL,
        i_clinical_question_notes IN table_clob DEFAULT NULL,
        o_id_sr_epis_interv       OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns list of surgical procedures for an ORIS episode                 
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             ORIS episode                            
    * @param i_id_sr_intervention     Table number with interventions ids     
    * @param i_flg_uncoded            flag to show coded and uncoded surgical procedure
    *
    * @param o_epis_surg_proc         Cursor with surgical procedures info
    * @param o_supplies_surg_proc     Cursor with default supplies 
    * @param o_error                  Error
    *                                                                        
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/20                              
    **************************************************************************/
    FUNCTION get_grid_epis_surg_proc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_sr_intervention IN table_number,
        i_flg_uncoded        IN VARCHAR2,
        o_epis_surg_proc     OUT pk_types.cursor_type,
        o_supplies_surg_proc OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Save or update information of surgical procedures (coded and uncoded),  
    * supplies and diagnoses associated with this surgical procedure          
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID                              
    * @param i_id_episode context     ORIS episode ID                         
    * @param i_id_sr_epis_interv      Table number with id_sr_epis_interv     
    * @param i_id_sr_intervention     Table number with interventions ID      
    * @param i_name_interv            Table varchar with names of uncoded surgical procedures
    * @param i_notes_sp               Table varchar with surgical procedures' notes
    * @param i_description_sp         Table varchar with surgical procedures' description
    * @param i_laterality             Table varchar with laterality code
    * @param i_supply                 Supply ID
    * @param i_supply_set             Parent supply set (if applicable)
    * @param i_supply_qty             Supply quantity
    * @param i_supply_loc             Supply location
    * @param i_dt_return              Estimated date of of return
    * @param i_supply_soft_inst       list
    * @param i_flg_cons_type          flag of consumption type
    * @param i_id_req_reason          Reasons for each supply
    * @param i_notes                  Request notes
    * @param i_diagnosis_surg_proc    Surgical procedures diagnosis XML
    * @param i_id_cdr_call            Rule event identifier.
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/23                              
    **************************************************************************/

    FUNCTION set_epis_surgical_procedures
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_episode_context IN episode.id_episode%TYPE,
        --surgical procedures 
        i_id_sr_epis_interv  IN table_number, --5
        i_id_sr_intervention IN table_number,
        i_name_interv        IN table_varchar,
        i_notes_sp           IN table_varchar,
        i_description_sp     IN table_varchar,
        i_flg_type           IN table_varchar, --10
        i_codification       IN table_number,
        i_laterality         IN table_varchar,
        i_surgical_site      IN table_varchar,
        --supplies
        i_supply           IN table_table_number,
        i_supply_set       IN table_table_number, --15
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number,
        i_flg_cons_type    IN table_table_varchar, --20
        i_id_req_reason    IN table_table_number,
        i_notes            IN table_table_varchar,
        -- team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number,
        i_tbl_prof       IN table_table_number, --25
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar,
        i_test           IN VARCHAR2,
        -- diagnoses
        i_diagnosis_surg_proc IN table_clob,
        -- clinical decision rules
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE,
        i_id_not_order_reason_ea  IN table_number, --30
        i_id_ct_io                IN table_table_varchar,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_clob,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Save or update information of surgical procedures (coded and uncoded),  
    * supplies and diagnoses associated with this surgical procedure          
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID                              
    * @param i_id_episode context     ORIS episode ID                         
    * @param i_id_sr_epis_interv      Table number with id_sr_epis_interv     
    * @param i_id_sr_intervention     Table number with interventions ID      
    * @param i_name_interv            Table varchar with names of uncoded surgical procedures
    * @param i_notes_sp               Table varchar with surgical procedures' notes
    * @param i_description_sp         Table varchar with surgical procedures' description
    * @param i_laterality             Table varchar with laterality code
    * @param i_supply                 Supply ID
    * @param i_supply_set             Parent supply set (if applicable)
    * @param i_supply_qty             Supply quantity
    * @param i_supply_loc             Supply location
    * @param i_dt_return              Estimated date of of return
    * @param i_supply_soft_inst       list
    * @param i_flg_cons_type          flag of consumption type
    * @param i_id_req_reason          Reasons for each supply
    * @param i_notes                  Request notes
    * @param i_diagnosis_surg_proc    Diagnosis information for the surgical procedure
    * @param i_id_cdr_call            Rule event identifier.
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/23                              
    **************************************************************************/

    FUNCTION set_epis_surg_proc_nocommit
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_episode_context IN episode.id_episode%TYPE,
        --surgical procedures 
        i_id_sr_epis_interv  IN table_number, --5
        i_id_sr_intervention IN table_number,
        i_name_interv        IN table_varchar,
        i_notes_sp           IN table_varchar,
        i_description_sp     IN table_varchar,
        i_flg_type           IN table_varchar, --10
        i_codification       IN table_number,
        i_laterality         IN table_varchar,
        i_surgical_site      IN table_varchar,
        --supplies
        i_supply           IN table_table_number,
        i_supply_set       IN table_table_number, --15
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number,
        i_flg_cons_type    IN table_table_varchar, --20
        i_id_req_reason    IN table_table_number,
        i_notes            IN table_table_varchar,
        -- team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number, --25
        i_tbl_prof       IN table_table_number,
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar,
        i_test           IN VARCHAR2,
        -- diagnoses
        i_diagnosis_surg_proc IN pk_edis_types.table_in_epis_diagnosis, --30
        -- clinical decision rules
        i_id_cdr_call             IN cdr_call.id_cdr_call%TYPE,
        i_id_not_order_reason_ea  IN table_number,
        i_id_ct_io                IN table_table_varchar DEFAULT NULL,
        i_clinical_question       IN table_table_number DEFAULT NULL,
        i_response                IN table_table_varchar DEFAULT NULL, --35
        i_clinical_question_notes IN table_table_clob DEFAULT NULL,
        i_id_inst_dest            IN institution.id_institution%TYPE DEFAULT NULL,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Check if has changes for surgical procedures tables         
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                                              
    * @param i_id_sr_epis_interv      Primary key of sr_epis_interv table  
    * @param i_laterality             Laterality code    
    * @param i_id_epis_diagnosis      Epis Diagnosis id
    * @param i_notes                  Surgical procedure notes
    * @param i_desc_interv            Surgical procedure description
    *
    * @param o_has_changes_sr_epis_interv  has changes (Y) or not (N) for the sr_epis_interv table                                                                         
    * @param o_has_changes_interv_desc  has changes (Y) or not (N) for the sr_epis_interv_desc table
    * @param o_error                   error description
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/23                              
    **************************************************************************/

    FUNCTION check_changes_surg_procedures
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_sr_epis_interv          IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_flg_type                   IN sr_epis_interv.flg_type%TYPE,
        i_interv_codification        IN sr_epis_interv.id_interv_codification%TYPE,
        i_laterality                 IN sr_epis_interv.laterality%TYPE,
        i_id_epis_diagnosis          IN sr_epis_interv.id_epis_diagnosis%TYPE,
        i_notes                      IN sr_epis_interv.notes%TYPE,
        i_desc_interv                IN sr_epis_interv_desc.desc_interv%TYPE,
        o_has_changes_sr_epis_interv OUT VARCHAR2,
        o_has_changes_interv_desc    OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_surg_proc_upd
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN sr_epis_interv.id_episode_context%TYPE,
        o_dt_last_upd OUT sr_epis_interv.dt_req_unc_tstz%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get the reasons cancels and the supplies associated with the surgical procedure
    *  to be cancelled       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_area                   The cancel reason area
    * @param i_id_sr_epis_interv      Primary key sr_epis_interv table    
    * @param i_id_sr_intervention     Surgical procedure intervention ID  
    *
    * @param o_reasons                Cursor with cancel reasons
    * @param o_supplies_to_remove     Cursor with supplies to be cancelled
    * @param o_labels                 Cursor with labels 
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/29                                 
    **************************************************************************/

    FUNCTION get_cancel_reasons_surg_proc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_area               IN cancel_rea_area.intern_name%TYPE,
        i_id_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_reasons            OUT pk_types.cursor_type,
        o_supplies_to_remove OUT pk_types.cursor_type,
        o_labels             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancel the surgical procedures and the supplies were chosen by the professional.
    * For the other supplies, will be deleted the association of the surgical procedure.     
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             ORIS episode ID
    * @param i_id_sr_epis_interv      Primary key sr_epis_interv table    
    * @param i_sup_to_be_cancelled    table number with supplies id to be cancelled
    * @param i_sr_cancel_reason       Cancel reason surgical procedure
    * @param i_notes                  Cancel notes
    *
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.4                                 
    * @since                          2010/09/30                                 
    **************************************************************************/

    FUNCTION set_cancel_epis_surg_proc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_sr_epis_interv   IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_sup_to_be_cancelled IN table_number,
        i_sr_cancel_reason    IN sr_epis_interv.id_sr_cancel_reason%TYPE,
        i_notes               IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status Y/N  N: not proceed with nursing intervention
    *                        
    * @author                        António Neto
    * @version                       v2.6.0.5
    * @since                         03-Mar-2011
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    );

    /*******************************************************************************************************************************************
    * cancel_assoc_icnp_interv        De-associate Integration of Therapeutic Attitudes
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_SR_EPIS_INTERV      ID of Surgery episode intervention
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          03-Mar-2011
    *******************************************************************************************************************************************/
    FUNCTION cancel_assoc_icnp_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * create_assoc_icnp_interv        Associate Integration of Therapeutic Attitudes
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_SR_EPIS_INTERV      ID of Surgery episode intervention
    * @param I_ID_EPISODE             ID of episode
    * @param I_ID_SR_INTERVENTION     ID of Surgery intervention
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          03-Mar-2011
    *******************************************************************************************************************************************/
    FUNCTION create_assoc_icnp_interv
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_sr_intervention IN intervention.id_intervention%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Check if exists an principal interv for the episode
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Id episode
    *
    * @param o_flg_principal            Y/N
    * @param o_error                   error description
    *
    * @author                         Rita Lopes
    * @version                        2.5
    * @since                          2011/10/20
    **************************************************************************/

    FUNCTION check_epis_interv_principal
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN sr_epis_interv.id_episode_context%TYPE,
        o_id_sr_epis_interv OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_flg_principal     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get surgical procedures summary page
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_context       Identifier of the Episode/Patient based on the i_flg_type
    * @param i_flg_type_context Flag to filter by Episode (E) or by Patient (P)
    * @param o_interv           Data cursor
    * @param o_labels           Labels cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   António Neto
    * @version                  2.6.1
    * @since                    2011-04-08
    *
    *********************************************************************************************/
    FUNCTION get_summ_interv_api
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_context                IN NUMBER,
        i_flg_type_context          IN VARCHAR2,
        o_interv                    OUT pk_types.cursor_type,
        o_labels                    OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if some occurrence of a surgery with given surgical procedures was initiated (surgery start date)
    * after the given date.
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_patient            Patient Id
    * @param i_id_sr_intervention    Surgical Procedure Id
    * @param i_start_date            Lower date to be considered
    * @param o_flg_started_procedure Y-the surgical procedure was started after the given date. N-otherwise
    * @param o_id_epis_sr_interv     List with the epis_sr_interv
    * @param o_error                 Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sofia Mendes
    * @version                  2.6.1
    * @since                    19-Apr-2011
    *
    *********************************************************************************************/
    FUNCTION check_surg_procedure
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patiet             IN patient.id_patient%TYPE,
        i_id_sr_intervention    IN intervention.id_intervention%TYPE,
        i_start_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_started_procedure OUT VARCHAR2,
        o_id_epis_sr_interv     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * List of coded surgical procedures for an institution       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    * @param o_surg_proc_list         List of coded surgical procedures 
    * @param o_error                  Error message 
    *           
    * @return                         TRUE/FALSE                                                             
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/04/27                              
    **************************************************************************/
    FUNCTION get_coded_surgical_procedures
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_surg_proc_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sr_interv_edit_permission
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_edit_permission OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get a surgical procedure team for CDA
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_sr_epis_interv     Surgical intervention Id
    *
    * @return                        The surgial intervention team
    *     
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-Ago-2014
    *
    *********************************************************************************************/
    FUNCTION get_surgical_proc_team_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN t_coll_proc_performed_cda;

    /********************************************************************************************
    * Get surgical procedures associated to a surgery for a given scope and status for CDA
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_scope              ID for scope
    * @param i_scope_type            Scope Type (E)pisode/(V)isit/(P)atient
    * @param i_flg_status            Flag status (S)cheduled / (P)roposal to add
    *
    * @return                        The surgial procedures associated to a surgery
    *     
    * @author                        Vanessa Barsottelli
    * @version                       2.6.4
    * @since                         07-Ago-2014
    *
    *********************************************************************************************/
    FUNCTION get_surgical_proc_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_scope   IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_flg_status IN table_varchar DEFAULT NULL
    ) RETURN t_coll_surgical_proc_cda;
    /********************************************************************************************
    * Get List of surgical procedures modifying factors
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_sr_intervention              ID for scope
    *
    * @return                        List modifying factors
    *     
    * @author                        Paulo Teixeira
    * @version                       2.6.5
    * @since                         2015 10 15
    *
    *********************************************************************************************/
    FUNCTION get_surg_proc_mod_fact
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_epis_interv  IN table_number,
        i_id_sr_intervention IN table_number,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get List of surgical procedures modifying factors
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_sr_epis_interv              ID for scope
    * @param i_id_sr_epis_interv_hist              ID for scope
    *
    * @return                        List modifying factors
    *     
    * @author                        Paulo Teixeira
    * @version                       2.6.5
    * @since                         2015 10 15
    *
    *********************************************************************************************/
    FUNCTION get_surg_proc_mod_fact_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv      IN sr_epis_interv_hist.id_sr_epis_interv%TYPE,
        i_id_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_surg_proc_mod_fact_flg_sel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_concept_term   IN concept_term.id_concept_term%TYPE,
        i_id_inst_owner     IN concept_term.id_inst_owner%TYPE,
        i_id_sr_epis_interv IN table_number
    ) RETURN VARCHAR2;
    --
    FUNCTION get_surg_proc_mod_fact_ids
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv      IN sr_epis_interv_hist.id_sr_epis_interv%TYPE,
        i_id_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE
    ) RETURN table_varchar;
    /********************************************************************************************
    * Get number of surgical procedures registered in intervention records in given scope
    *
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return              Count of records
    *
    * @author              Anna Kurowska
    * @since               2017/03/07
       ********************************************************************************************/
    FUNCTION get_sr_interv_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    FUNCTION get_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN VARCHAR2,
        i_flg_filter    IN VARCHAR2 DEFAULT 'S',
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_codification  IN codification.id_codification%TYPE,
        i_value         IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION handle_unav
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_current_section   IN ds_component.internal_name%TYPE,
        i_unav_num          IN NUMBER DEFAULT 1,
        io_tab_sections     IN OUT t_table_ds_sections,
        io_tab_def_events   IN OUT t_table_ds_def_events,
        io_tab_events       IN OUT t_table_ds_events,
        io_tab_items_values IN OUT t_table_ds_items_values,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_need_surgery              IN VARCHAR2 DEFAULT 'N',
        i_waiting_list              IN waiting_list.id_waiting_list%TYPE,
        i_component_name            IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type            IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        i_adm_indication            IN adm_indication.id_adm_indication%TYPE,
        i_inst_location             IN institution.id_institution%TYPE,
        i_id_department             IN department.id_department%TYPE,
        i_dep_clin_serv             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dep_clin_serv_surg        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sch_lvl_urg               IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_id_surg_proc_princ        IN intervention.id_intervention%TYPE,
        i_unav_val                  IN NUMBER,
        i_unav_begin                IN VARCHAR2,
        i_unav_duration             IN NUMBER,
        i_unav_duration_mea         IN unit_measure.id_unit_measure%TYPE,
        i_unav_end                  IN VARCHAR2,
        i_ask_hosp                  IN VARCHAR2,
        i_order_set                 IN VARCHAR2,
        i_anesth_field              IN VARCHAR2,
        i_anesth_value              IN VARCHAR2,
        i_adm_phy                   IN professional.id_professional%TYPE,
        o_section                   OUT pk_types.cursor_type,
        o_def_events                OUT pk_types.cursor_type,
        o_events                    OUT pk_types.cursor_type,
        o_items_values              OUT pk_types.cursor_type,
        o_data_val                  OUT CLOB,
        o_data_diag                 OUT pk_types.cursor_type,
        o_data_proc                 OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_duration_unit_measure_ds
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hours        IN adm_request.expected_duration%TYPE,
        i_date         IN adm_request.dt_admission%TYPE, --Value is sent in minutes
        o_value        OUT NUMBER,
        o_unit_measure OUT unit_measure.id_unit_measure%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_filter_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_procedure_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN table_varchar,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(2000);
    g_sr_dept      INTEGER;
    g_found        BOOLEAN;
    g_flg_time_g   VARCHAR2(1) := 'G';

    g_active      CONSTANT VARCHAR2(1) := 'A';
    g_inactive    CONSTANT VARCHAR2(1) := 'I';
    g_cancel      CONSTANT VARCHAR2(1) := 'C';
    g_not_orded   CONSTANT VARCHAR2(1) := 'N';
    g_surg_interv CONSTANT VARCHAR2(1) := 'S';
    g_value_y     CONSTANT VARCHAR2(1) := 'Y';
    g_value_n     CONSTANT VARCHAR2(1) := 'N';
    g_value_c     CONSTANT VARCHAR2(1) := 'C';
    g_value_p     CONSTANT VARCHAR2(1) := 'P'; --Botão da pesquisa
    g_value_u     CONSTANT VARCHAR2(1) := 'U';
    g_posit_req   CONSTANT VARCHAR2(1) := 'R';
    g_posit_exec  CONSTANT VARCHAR2(1) := 'F';
    g_posit_canc  CONSTANT VARCHAR2(1) := 'C';
    g_posit_part  CONSTANT VARCHAR2(1) := 'P';

    g_reserv_req  CONSTANT VARCHAR2(1) := 'R';
    g_reserv_exec CONSTANT VARCHAR2(1) := 'F';
    g_reserv_canc CONSTANT VARCHAR2(1) := 'C';

    g_posit_verif_n CONSTANT VARCHAR2(1) := 'N';
    g_posit_verif_y CONSTANT VARCHAR2(1) := 'Y';

    g_available CONSTANT VARCHAR2(1) := 'Y';

    g_epis_interv_type_p CONSTANT VARCHAR2(1) := 'P';
    g_epis_interv_type_s CONSTANT VARCHAR2(1) := 'S';

    g_surg_time_ic CONSTANT sr_surgery_time.flg_type%TYPE := 'IC';
    g_surg_time_fc CONSTANT sr_surgery_time.flg_type%TYPE := 'FC';

    g_interv_req  CONSTANT VARCHAR2(1) := 'R';
    g_interv_tmp  CONSTANT VARCHAR2(1) := 'T';
    g_interv_part CONSTANT VARCHAR2(1) := 'E';
    g_interv_exec CONSTANT VARCHAR2(1) := 'F';
    g_interv_can  CONSTANT VARCHAR2(1) := 'C';

    g_freq_interv CONSTANT VARCHAR2(1) := 'M';

    g_material_kit CONSTANT sr_equip.id_sr_equip%TYPE := 72;

    g_val_team CONSTANT sys_domain.val%TYPE := 'C';

    -- FLG_TYPE in SR_EPIS_INTERV_DESC for Surgery
    g_surg_flg_type      CONSTANT VARCHAR2(1) := 'S';
    g_flg_type_rec       CONSTANT epis_prof_rec.flg_type%TYPE := 'R';
    g_equip_flg_type_all CONSTANT sr_equip.flg_type%TYPE := 'T';
    g_equip_flg_type_r   CONSTANT sr_equip.flg_type%TYPE := 'R';
    g_equip_flg_type_c   CONSTANT sr_equip.flg_type%TYPE := 'C';

    g_reserv_flg_status_r CONSTANT sr_reserv_req.flg_status%TYPE := 'R';
    g_reserv_flg_status_f CONSTANT sr_reserv_req.flg_status%TYPE := 'F';
    g_reserv_flg_status_c CONSTANT sr_reserv_req.flg_status%TYPE := 'C';

    g_flg_type_o      CONSTANT VARCHAR2(1) := 'O';
    g_flg_type_p      CONSTANT VARCHAR2(1) := 'P';
    g_software_oris   CONSTANT software.id_software%TYPE := 2;
    g_flg_code_type_c CONSTANT VARCHAR2(1) := 'C';
    g_flg_code_type_u CONSTANT VARCHAR2(1) := 'U';

    g_sr_consent_status_a CONSTANT VARCHAR2(1) := 'A';
    g_sr_consent_status_i CONSTANT VARCHAR2(1) := 'I';
    g_sr_consent_status_o CONSTANT VARCHAR2(1) := 'O';

    g_flg_type_e CONSTANT sr_posit_rel.flg_type%TYPE := 'E';

    g_selected VARCHAR2(1);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_flg_type_context_pat_p     CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_flg_type_context_epis_e    CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_flg_status_epis_inactive_i CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_flg_status_epis_active_a   CONSTANT VARCHAR2(1 CHAR) := 'A';

    g_sei_flg_code_type_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_sei_flg_status      CONSTANT sys_domain.code_domain%TYPE := 'SR_EPIS_INTERV.FLG_STATUS';
    g_sei_flg_type        CONSTANT sys_domain.code_domain%TYPE := 'SR_EPIS_INTERV.FLG_TYPE';
    g_sei_laterality      CONSTANT sys_domain.code_domain%TYPE := 'SR_EPIS_INTERV.LATERALITY';

    --Detail Screen (AN 11-May-2011 [ALERT-148089])
    g_sd_flg_status     CONSTANT sys_domain.code_domain%TYPE := 'SR_RESERV_REQ.FLG_STATUS';
    g_sd_flg_status_aux CONSTANT sys_domain.code_domain%TYPE := 'SR_RESERV_REQ.FLG_STATUS_DET';

    g_category_nurse CONSTANT category.flg_type%TYPE := 'N';
    g_exception EXCEPTION;

    g_sei_flg_status_n CONSTANT sr_epis_interv.flg_status%TYPE := 'N';

    --
    g_sr_flg_pat_status_a sr_surgery_record.flg_pat_status%TYPE := 'A';
    g_sr_flg_pat_status_w sr_surgery_record.flg_pat_status%TYPE := 'W';
    g_sr_flg_pat_status_v sr_surgery_record.flg_pat_status%TYPE := 'V';
    g_sr_flg_pat_status_p sr_surgery_record.flg_pat_status%TYPE := 'P';
    g_sr_flg_pat_status_r sr_surgery_record.flg_pat_status%TYPE := 'R';
    g_sr_flg_pat_status_s sr_surgery_record.flg_pat_status%TYPE := 'S';
    --
    g_has_modifier CONSTANT VARCHAR2(200 CHAR) := 'HAS_MODIFIER';

    g_unit_measure_hours CONSTANT NUMBER := 1041;
    g_unit_measure_days  CONSTANT NUMBER := 1039;

END pk_sr_planning;
/
