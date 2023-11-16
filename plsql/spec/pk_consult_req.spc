/*-- Last Change Revision: $Rev: 2028574 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_consult_req IS

    FUNCTION set_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN consult_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_consult_type     IN consult_req.consult_type%TYPE,
        i_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        i_notes            IN consult_req.notes%TYPE,
        i_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested   IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_complaint     IN consult_req.id_complaint%TYPE,
        i_commit_data      IN VARCHAR2,
        i_reason_for_visit IN consult_req.reason_for_visit%TYPE DEFAULT NULL,
        i_epis_type        IN consult_req.id_epis_type%TYPE DEFAULT NULL,
        i_flg_type         IN VARCHAR2,
        i_notes_admin      IN consult_req.notes_admin%TYPE DEFAULT NULL,
        o_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN consult_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_consult_type     IN consult_req.consult_type%TYPE,
        i_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        i_notes            IN consult_req.notes%TYPE,
        i_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested   IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_complaint     IN consult_req.id_complaint%TYPE,
        i_flg_type         IN VARCHAR2,
        o_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_consult_req
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        i_flg         IN consult_req.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_consult_req
    (
        i_lang         IN language.id_language%TYPE,
        i_consult_req  IN consult_req.id_consult_req%TYPE,
        i_prof_cancel  IN profissional,
        i_notes_cancel IN consult_req.notes_cancel%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_consult_req
    (
        i_lang          IN language.id_language%TYPE,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_prof_cancel   IN profissional,
        i_notes_cancel  IN consult_req.notes_cancel%TYPE,
        i_commit_data   IN VARCHAR2,
        i_flg_discharge IN VARCHAR2 DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_consult_req_noprofcheck
    (
        i_lang         IN language.id_language%TYPE,
        i_consult_req  IN consult_req.id_consult_req%TYPE,
        i_prof_cancel  IN profissional,
        i_notes_cancel IN consult_req.notes_cancel%TYPE,
        i_commit_data  IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_consult_req_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_consult_req      IN consult_req.id_consult_req%TYPE,
        i_prof             IN profissional,
        i_deny_acc         IN consult_req_prof.flg_status%TYPE,
        i_denial_justif    IN consult_req_prof.denial_justif%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_notes_admin      consult_req.notes_admin%TYPE,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_prof             IN profissional,
        o_req              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cons_req_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        o_req         OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_subs_req_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN consult_req.id_episode%TYPE,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        o_flg_status     OUT VARCHAR2,
        o_status_string  OUT VARCHAR2,
        o_flg_finished   OUT VARCHAR2,
        o_flg_canceled   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_subs_req
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN consult_req.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_req      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Equal to GET_SUBS_REQ, with additional out variable o_create.
    *
    * @param      i_lang              language identifier.
    * @param      i_epis              episode identifier.
    * @param      i_prof              logged professional structure.
    * @param      i_flg_type          consult type.
    * @param      o_req               subsequent consults requested.
    * @param      o_create            avail_butt_create.
    * @param      o_error             erro
    *
    * @return     boolean             false if errors occur, true otherwise.
    * @author     Pedro Carneiro
    * @version    1.0
    * @since      2009/04/23
    * @notes      Based on get_subs_req
    */
    FUNCTION get_subs_req_amb
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN consult_req.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_req      OUT pk_types.cursor_type,
        o_create   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_subs_req_det
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_prof        IN profissional,
        o_req         OUT pk_types.cursor_type,
        o_req_det     OUT pk_types.cursor_type,
        o_sch_det     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_aux_reply
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        o_cursor      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_prof  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_accept_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_consult_req_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_consult_req
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_consult_req_det
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_consult_req_status
    (
        i_lang          IN language.id_language%TYPE,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_dt_sched_str  IN VARCHAR2,
        i_prof          IN profissional,
        i_flg_type_date IN consult_req.flg_type_date%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. 
    * Patient consults requested but not scheduled.
    *
    * @param      I_LANG              língua registada como preferência do profissional.
    * @param      I_PROF              object (ID do profissional, ID da instituição, ID do software).
    * @param      I_DT                data das requisições
    * @param      I_ID_PATIENT        Id do paciente
    * @param      o_list              consultas
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     Luís Gaspar
    * @version    0.1
    * @since      2007/03/27
    * @notes      Based on get_consult_req_list
    */
    FUNCTION get_patient_consult_req_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_followup_default_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE, -- tco 30/05/2008
        o_cur           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professional_dest_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_type      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE, -- tco 26/05/2008
        o_cursor        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Similar to GET_PROFESSIONAL_DEST_LIST.
    * Returns professionals of same category as the caller.
    *
    * @param      i_lang            language identifier.
    * @param      i_prof            logged professional structure.
    * @param      i_dep_clin_serv   dep_clin_serv identifier.
    * @param      i_flg_type        'M' consulta médica; 'S' consulta de especialidade.
    * @param      i_prof_cat_type   logged professional category.
    * @param      o_cursor          cursor.
    * @param      o_error           error.
    *
    * @return     false if errors occur, true otherwise.
    * @author     Pedro Carneiro
    * @version    1.0
    * @since      2009/04/23
    * @notes      Based on GET_PROFESSIONAL_DEST_LIST.
    */
    FUNCTION get_professional_dest_list_amb
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_type      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_cursor        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Check if it exists conflicts for a given dep_clin_serv ID associated to a appointment
    *
    * @param    I_LANG               Preferred language ID
    * @param    I_PROF               Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_DEP_CLIN_SERV   Department clinical service ID associated to a appointment
    * @param    O_FLG_CONFLICT       Flag that indicates if it exists conflicts (Y/N)
    *
    * @return   BOOLEAN: true in case of conflict and false otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/29
    ********************************************************************************************/
    FUNCTION check_consult_req_conflict
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_conflict     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retorna o motivo da consulta ou o do agendamento
    *
    * @param i_lang                ID language
    * @param i_id_consult_req      ID consult requisition
    *
    * @param o_reason              The reason for next consult
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/24
    **********************************************************************************************/
    FUNCTION get_consult_req_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        o_reason         OUT consult_req.reason_for_visit%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Chama a função set_consult_req com o valor do parâmetro commit_data a YES, 
    * inclui o paramatro do motivo de consulta de texto livre
    *
    * @param I_LANG - Língua registada como preferência do profissional 
    * @param I_EPISODE - ID do episódio 
    * @param I_PROF_REQ - ID do profissional q requisita exame / consulta 
    * @param I_PAT - doente para quem é pedido o exame / consulta 
    * @param I_INSTIT_REQUESTS - instituição requisitante. Pode ser NULL  
    * @param I_INSTIT_REQUESTED - instituição requisitada 
    * @param I_CONSULT_TYPE, I_CLINICAL_SERVICE, I_DEP_CLIN_SERV - Tipo de 
                             exame / consulta requisitada. Se requisição é externa, 
                         preenche-se ID_CLINICAL_SERVICE (se o tipo de serviço 
                         pretendido está registado na BD da instituição 
                         requisitante) ou CONSULT_TYPE (campo de texto livre).
                         Se requisição é interna, selecciona-se o tipo de 
                         serviço (ID_CLINICAL_SERVICE) e o departamento (DEP_CLIN_SERV).
    * @param I_DT_SCHEDULED - data agendada 
    * @param I_NOTES - notas do prof. requisitante 
    * @param I_PROF_REQUESTED - prof requisitado (req. internas) 
    * @param I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                               como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param i_id_complaint - Id of complaint from table COMPLAINT
    * @param i_reason_for_visit - Reason of complaint
    *
    * @param o_consult_req         ID of consult req
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/24
    **********************************************************************************************/

    FUNCTION set_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN consult_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_consult_type     IN consult_req.consult_type%TYPE,
        i_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        i_notes            IN consult_req.notes%TYPE,
        i_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested   IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_complaint     IN consult_req.id_complaint%TYPE,
        i_reason_for_visit IN consult_req.reason_for_visit%TYPE,
        i_flg_type         IN VARCHAR2,
        o_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    /* get content id from APPOINTMENT using available data from consult_req 
    * INLINE FUNCTION
    * 
    * @return                      APPOINTMENT.id_content%TYPE
    *                        
    * @author   Telmo
    * @version  2.6
    * @date     05-01-2010
    */
    FUNCTION get_content_dcs_code
    (
        i_flg_type            IN consult_req.flg_type%TYPE,
        i_id_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_id_inst_requested   IN consult_req.id_inst_requested%TYPE,
        i_sch_type            IN sch_event.dep_type%TYPE,
        i_ids_content         IN table_varchar
    ) RETURN appointment.code_appointment%TYPE;

    /*  search physician, nurse and nutrition appoint. requisitions by 
    * - patient data
    * - appointment id (see new table appointment)
    * - dates
    * These are all AND conditions.
    *
    * @param i_lang                 language id
    * @param i_prof                 professional data
    * @param i_id_market            market id needed for patient searching.
    * @param i_pat_search_values    assoc. array (hashtable) with patient criteria and their values to search for
    * @param i_ids_content          appointment table content ids. 
    * @param i_min_date             suggested date (if exists) must be higher than i_min_date, if supplied
    * @param i_min_date             suggested date (if exists) must be lower than i_max_date, if supplied
    * @param i_id_cancel_reason     cancel reason. If exists, the search must be conducted among canceled reqs.
    * @param i_ids_prof             list of requested profs, those that will perform the appointment. reqs with no requested prof are always considered
    * @param i_reason_for_visit     reason for visit (motivo da consulta)
    * @param i_sch_type             sch_type. If null then all are considered. C=medical app.  N=nurse app.  U=nutrition app.
    * @param o_error                Error data
    *
    * @return                      True on success, false otherwise
    *                        
    * @author   Telmo
    * @version  2.6
    * @date     05-01-2010
    */
    FUNCTION search_consult_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_market         IN market.id_market%TYPE,
        i_pat_search_values IN pk_utils.hashtable_pls_integer,
        i_ids_content       IN table_varchar,
        i_min_date          IN VARCHAR2,
        i_max_date          IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_ids_prof          IN table_number,
        i_reason_for_visit  IN VARCHAR2,
        i_sch_type          IN sch_dep_type.dep_type%TYPE,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Send a consult_request to history
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req       future events identifier
    *
    * @param  o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION send_cr_to_history
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert consult req no commit
    *
    * @param      i_lang       language identifier              
    * @param   i_prof                 
    * @param     i_patient            
    * @param     i_episode            
    * @param     i_epis_type    
    * @param     i_request_prof              
    * @param     i_inst_req_to        
    * @param     i_sch_event          
    * @param     i_dep_clin_serv      
    * @param     i_complaint          
    * @param     i_dt_begin_event     
    * @param     i_dt_end_event       
    * @param     i_priority           
    * @param     i_contact_type       
    * @param     i_notes              
    * @param     i_instructions       
    * @param     i_room               
    * @param     i_request_type       
    * @param     i_request_responsable
    * @param     i_request_reason     
    * @param     i_prof_approval    
    * @param     i_language           
    * @param     i_recurrence         
    * @param     i_status             
    * @param     i_frequency          
    * @param     i_dt_rec_begin       
    * @param     i_dt_rec_end         
    * @param     i_nr_events          
    * @param     i_week_day           
    * @param     i_week_nr            
    * @param     i_month_day          
    * @param     i_month_nr           
    * @param     id_task_dependency   
    * @param     i_flg_origin_module  
    * @param     i_episode_to_exec    
    * @param     o_consult_req        return cursor
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION insert_consult_req_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN consult_req.dt_begin_event%TYPE,
        i_dt_end_event        IN consult_req.dt_end_event%TYPE,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN consult_req.dt_rec_begin%TYPE,
        i_dt_rec_end          IN consult_req.dt_rec_end%TYPE,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        id_task_dependency    IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_flg_origin_module   IN VARCHAR2 DEFAULT NULL,
        i_episode_to_exec     IN consult_req.id_episode_to_exec%TYPE DEFAULT NULL,
        o_consult_req         OUT consult_req.id_consult_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update consult req no commit
    *
    * @param     i_consult_req
    * @param     i_lang       language identifier             
    * @param     i_prof                 
    * @param     i_patient            
    * @param     i_episode            
    * @param     i_epis_type 
    * @param     i_request_prof                
    * @param     i_inst_req_to        
    * @param     i_sch_event          
    * @param     i_dep_clin_serv      
    * @param     i_complaint          
    * @param     i_dt_begin_event     
    * @param     i_dt_end_event       
    * @param     i_priority           
    * @param     i_contact_type       
    * @param     i_notes              
    * @param     i_instructions       
    * @param     i_room               
    * @param     i_request_type       
    * @param     i_request_responsable
    * @param     i_request_reason     
    * @param     i_prof_approval        
    * @param     i_language           
    * @param     i_recurrence         
    * @param     i_status             
    * @param     i_frequency          
    * @param     i_dt_rec_begin       
    * @param     i_dt_rec_end         
    * @param     i_nr_events          
    * @param     i_week_day           
    * @param     i_week_nr            
    * @param     i_month_day          
    * @param     i_month_nr           
    * @param     id_task_dependency   
    * @param     i_flg_origin_module  
    * @param     i_episode_to_exec    
    * @param     o_consult_req        return cursor
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION update_consult_req_nc
    (
        i_consult_req         IN consult_req.id_consult_req%TYPE,
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN consult_req.dt_begin_event%TYPE,
        i_dt_end_event        IN consult_req.dt_end_event%TYPE,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN consult_req.dt_rec_begin%TYPE,
        i_dt_rec_end          IN consult_req.dt_rec_end%TYPE,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel future events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      patient identifier
    * @param      i_cancel_reason      cancel reason
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/24
    **********************************************************************************************/
    FUNCTION cancel_future_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_cancel_reason IN consult_req.id_cancel_reason%TYPE,
        i_cancel_notes  IN consult_req.notes_cancel%TYPE,
        i_commit        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * cancel future events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      patient identifier
    * @param      i_cancel_reason      cancel reason
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/24
    **********************************************************************************************/
    FUNCTION cancel_future_events_nc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_cancel_reason IN consult_req.id_cancel_reason%TYPE,
        i_cancel_notes  IN consult_req.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Approves a future event request
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_consult_req       future events identifier
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    *
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/02
    **********************************************************************************************/
    FUNCTION set_fe_approved
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Rejects a future event request
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_consult_req       future events identifier
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    *
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/02
    **********************************************************************************************/
    FUNCTION set_fe_rejected
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * SEND TO HOLDING LIST
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req        EVENT IDENTIFIER
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/
    FUNCTION send_cr_to_holding_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Future Events task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_consult_req         diet request identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_description
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        i_desc_type      IN VARCHAR2
    ) RETURN CLOB;
    --
    FUNCTION undo_cancel_consult_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION inactivate_consult_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    g_error                  VARCHAR2(2000);
    g_consult_req_stat_req   consult_req.flg_status%TYPE;
    g_consult_req_stat_read  consult_req.flg_status%TYPE;
    g_consult_req_stat_reply consult_req.flg_status%TYPE;
    --G_CONSULT_REQ_STAT_REP_READ CONSULT_REQ.FLG_STATUS%TYPE;
    g_consult_req_stat_cancel   consult_req.flg_status%TYPE;
    g_consult_req_hold_list     consult_req.flg_status%TYPE;
    g_consult_req_stat_auth     consult_req.flg_status%TYPE;
    g_consult_req_stat_apr      consult_req.flg_status%TYPE;
    g_consult_req_stat_proc     consult_req.flg_status%TYPE;
    g_consult_req_stat_sched    consult_req.flg_status%TYPE;
    g_consult_req_stat_rejected consult_req.flg_status%TYPE;
    g_cons_req_prof_read        consult_req_prof.flg_status%TYPE;
    g_cons_req_prof_accept      consult_req_prof.flg_status%TYPE;
    g_cons_req_prof_deny        consult_req_prof.flg_status%TYPE;
    g_found                     BOOLEAN;
    g_accept                    sys_domain.code_domain%TYPE;
    g_flg_subs_img              VARCHAR2(1);
    g_flg_first_img             VARCHAR2(1);
    g_sched                     VARCHAR2(1);
    g_not_sched                 VARCHAR2(1);
    g_flg_subs                  VARCHAR2(1);
    g_flg_first                 VARCHAR2(1);
    g_flg_doctor                category.flg_type%TYPE;
    g_sched_canc                schedule.flg_status%TYPE;
    g_sched_pend                schedule.flg_status%TYPE;

    g_prof_active professional.flg_state%TYPE;

    g_cat_type_tech category.flg_type%TYPE;
    g_cat_type_phys category.flg_type%TYPE;

    g_epis_canc    episode.flg_status%TYPE;
    g_dcst_consult VARCHAR2(1);

    g_selected        VARCHAR2(1);
    g_flg_available   VARCHAR2(1);
    g_flg_type_date_h VARCHAR2(1);
    g_flg_type_date_a VARCHAR2(1);
    g_flg_type_date_m VARCHAR2(1);

    g_yes VARCHAR2(1);
    g_no  VARCHAR2(1);

    g_active                     VARCHAR2(1);
    g_sch_event_id_followup      sch_event.id_sch_event%TYPE;
    g_sch_event_id_followup_spec sch_event.id_sch_event%TYPE;

    g_sch_event_id_followup_nurse sch_event.id_sch_event%TYPE;

    g_nurse_category category.flg_type%TYPE := 'N';

    g_exception       EXCEPTION;
    g_exception_msg   EXCEPTION;
    g_exception_msg_1 EXCEPTION;
    g_exception_msg_2 EXCEPTION;

    g_flg_type_subsequent consult_req.flg_type%TYPE := 'S';
    g_flg_type_speciality consult_req.flg_type%TYPE := 'E';
    g_flg_type_waitlist   consult_req.flg_type%TYPE := 'W';
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);
    g_prof_cat_administrative CONSTANT category.flg_type%TYPE := 'A';
END;
/
