/*-- Last Change Revision: $Rev: 2028708 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hand_off AS
    --

    PROCEDURE delete_hand_off_event
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_id_sys_alert   IN NUMBER DEFAULT 32
    );

    /********************************************************************************************
    * Get the type of hand-off used in the current market.
    *
    * @param   i_lang                 language associated to the professional executing the request
    * @param   i_prof                 professional, institution and software ids
    * @param   o_hand_off_type        configured hand-off type (N) Normal (M) Multiple
    * @param   o_error                error message
    *                        
    * @return  TRUE if sucess, FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.5.0.7
    * @since                          28-10-2009
    **********************************************************************************************/
    FUNCTION get_hand_off_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_hand_off_type OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the professional responsible for the episode
    *
    * @param   I_LANG            language associated to the professional executing the request
    * @param   I_PROF            professional, institution and software ids
    * @param   i_episode         episode ID
    * @param   i_flg_type        Professional category: D - Doctor; N - Nurse
    * @param   i_hand_off_type   Hand-off mechanism
    * @param   i_flg_profile     Type of profile (S)pecialist (R)esident (I)ntern (N)urse
    * @param   i_id_speciality   Physician speciality (send NULL for nursing professionals)
    * @param   i_flg_resp_type   Type of responsability: (E) Episode - default (O) Overall
    *                        
    * @return  professional ID
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          21-08-2009
    *
    * @alter                          José Brito
    * @version                        2.5.0.7
    * @since                          21-10-2009
    **********************************************************************************************/
    FUNCTION get_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_flg_profile   IN profile_template.flg_profile%TYPE,
        i_id_speciality IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_resp_type IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT 'E'
    ) RETURN NUMBER;

    /********************************************************************************************
    * Set the professional responsasible for the episode on alerts event (consults for approval)
    *
    * @param   I_LANG            language associated to the professional executing the request
    * @param   I_PROF            professional, institution and software ids
    * @param   i_tot_epis        List of episodes
    *                        
    * @return  professional ID
    * 
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          15-04-2010
    *
    **********************************************************************************************/

    FUNCTION set_prof_responsible_alert
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_tot_epis IN table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Registar os pedidos de transferência de responsabilidade
    *  A transferência de responsabilidade poderá ser efectuada sobre vários episódios.
    *  Será possivél efectuar a transf. de responsabilidade para um ou vários profissionais.
    *  O mesmo poderá acontecer com as especialidades, uma ou várias especialidades.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_to                Array dos profissionais a quem foi pedido a transferência de responsabilidade   
    * @param i_tot_epis               Array com o número total de episódios para os quais foi pedido transferência de responsabilidade
    * @param i_epis_pat               Array com os IDs episódios / pacientes para os quais foi pedido transferência de responsabilidade
    * @param i_cs_or_dept             Array dos serviços clinicos ou departamentos onde foi efectuado o pedido a transferência de responsabilidade.        
    * @param i_notes                  Array de Notas
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_flg_resp               Pode assumir 2 valores: G -  Assumir responsabilidade do paciente nas grelhas de entrada
                                                              H -  Hand- Off                   
    * @param i_flg_profile            Type of profile: (S) specialist (R) resident (I) intern (N) nurse
    * @param i_sysdate                Current date
    * @param i_id_speciality          Responsability request speciality
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/08/11
    *
    * @alter                          José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/02
    **********************************************************************************************/
    FUNCTION create_epis_prof_resp
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_to               IN table_varchar,
        i_tot_epis              IN table_number,
        i_epis_pat              IN table_number,
        i_cs_or_dept            IN table_number,
        i_notes                 IN table_varchar,
        i_flg_type              IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp              IN VARCHAR2,
        i_flg_profile           IN profile_template.flg_profile%TYPE DEFAULT NULL,
        i_sysdate               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_speciality         IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        i_priority              IN NUMBER DEFAULT NULL,
        i_sbar_note             IN CLOB DEFAULT NULL,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg_body              OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Registar os pedidos de transferência de responsabilidade
    *  A transferência de responsabilidade poderá ser efectuada sobre vários episódios.
    *  Será possivél efectuar a transf. de responsabilidade para um ou vários profissionais.
    *  O mesmo poderá acontecer com as especialidades, uma ou várias especialidades.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_to                Array dos profissionais a quem foi pedido a transferência de responsabilidade   
    * @param i_tot_epis               Array com o número total de episódios para os quais foi pedido transferência de responsabilidade
    * @param i_epis_pat               Array com os IDs episódios / pacientes para os quais foi pedido transferência de responsabilidade
    * @param i_cs_or_dept             Array dos serviços clinicos ou departamentos onde foi efectuado o pedido a transferência de responsabilidade.        
    * @param i_notes                  Array de Notas
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_flg_resp               Pode assumir 2 valores: G -  Assumir responsabilidade do paciente nas grelhas de entrada
                                                              H -  Hand- Off                   
    * @param i_flg_profile            Type of profile: (S) specialist (R) resident (I) intern (N) nurse
    * @param i_sysdate                Current date
    * @param i_id_speciality          Responsability request speciality
    * @param o_epis_prof_resp         List of created id's
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/08/11
    *
    * @alter                          José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/02
    **********************************************************************************************/
    FUNCTION create_epis_prof_resp_api
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_to        IN table_varchar,
        i_tot_epis       IN table_number,
        i_epis_pat       IN table_number,
        i_cs_or_dept     IN table_number,
        i_notes          IN table_varchar,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp       IN VARCHAR2,
        i_flg_profile    IN profile_template.flg_profile%TYPE DEFAULT NULL,
        i_sysdate        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_speciality  IN epis_multi_prof_resp.id_speciality%TYPE,
		i_sbar_note      IN CLOB DEFAULT NULL,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_epis_prof_resp OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Change the status of the hand-off requests (CANCEL, ACCEPT or REJECT).
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_tot_epis               Array com o número total de episódios de transferência de responsabilidade,que o profissional vai aceitar, cancelar ou rejeitar
    * @param i_epis_prof_resp         Array com os IDs dos episódios de transferência de responsabilidade
    * @param i_flg_status             Status da Transferência de responsabilidade:  C - Cancelado;
                                                                                    F- Final;
                                                                                    D- Rejeitado        
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_notes                  Notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/08/11
    *
    * @alter                          José Brito
    * @version                        2.5.0.7 
    * @since                          2009/10/29
    **********************************************************************************************/
    FUNCTION set_epis_prof_resp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tot_epis       IN table_number,
        i_epis_prof_resp IN table_varchar,
        i_flg_status     IN epis_prof_resp.flg_status%TYPE,
        i_flg_type       IN epis_prof_resp.flg_type%TYPE,
        i_notes          IN epis_prof_resp.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a responsability record.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   i_sysdate                  Record date
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          02-02-2011
    **********************************************************************************************/
    FUNCTION call_cancel_request_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_sysdate          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Change the status of the hand-off requests (CANCEL, ACCEPT or REJECT).
    * IMPORTANT: Database internal function.
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_tot_epis               Array com o número total de episódios de transferência de responsabilidade,que o profissional vai aceitar, cancelar ou rejeitar
    * @param i_epis_prof_resp         Array com os IDs dos episódios de transferência de responsabilidade
    * @param i_flg_status             Status da Transferência de responsabilidade:  C - Cancelado;
                                                                                    F- Final;
                                                                                    D- Rejeitado        
    * @param i_flg_type               Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param i_notes                  Notes
    * @param i_sysdate                Current date
    * @param i_hand_off_type          Hand-off mechanism (N) Normal (M) Multiple
    * @param i_one_step_process       One step process (simulating acceptance)? (Y) Yes (N) No - default
    * @param o_refresh_mview          Update grids? (Y) Yes (N) No
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito (Based on SET_EPIS_PROF_RESP by Emília Taborda)
    * @version                        2.5.0.7 
    * @since                          2009/10/29
    **********************************************************************************************/
    FUNCTION call_set_epis_prof_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_tot_epis         IN table_number,
        i_epis_prof_resp   IN table_varchar,
        i_flg_status       IN epis_prof_resp.flg_status%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_sysdate          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_hand_off_type    IN sys_config.value%TYPE,
        i_one_step_process IN VARCHAR2 DEFAULT 'N',
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_refresh_mview    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Listar os pedidos de transferência de responsabilidade para o profissional
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_epis_presp             Todos os pedidos de transf. de responsabilidade efectuados ao profissional
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/08/11
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_epis_presp OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de todas os pacientes sobre os quais o profissional é responsavél (da urgência)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_type               type of hand-off: (D) Physician (N) Nurse
    * @param i_flg_show_only_resp     Show only episodes whose current professional is responsible?
    * @param o_patient                Todos os pacientes e sua informação adicional
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/16
    *                        
    * @changed by                     Alexandre Santos
    * @version                        2.6.0.3.4 
    * @since                          2010/11/26
    **********************************************************************************************/
    FUNCTION get_grid_hand_off_cab
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN VARCHAR2,
        i_flg_show_only_resp IN VARCHAR2,
        o_patient            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Gets the list of all patients whose responsible is the current user
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param i_flg_type               type of hand-off: (D) Physician (N) Nurse
    * @param o_patient                All patients list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.0.3.4 
    * @since                          2010/11/26
    **********************************************************************************************/
    FUNCTION get_grid_hand_off_cab
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2 DEFAULT NULL,
        o_patient  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de toda a informação associada a cada episódio:
                             - Sinais Vitais
                             - Diagnósticos
                             - Intervenções
                             - Analises
                             - Exames de imagens
                             - Medicação
                             - Notas de passagem de turno
    *                                                          
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_diag                   Todos os diagnóstico do episódio
    * @param o_sign_v                 Todos os sinais vitais do episódio
    * @param o_title_analy            Lista dos títulos com as descrições dos status de cada análise
    * @param o_analysis               Todas as análises do episódio
    * @param o_title_ex_imag          Lista dos títulos com as descrições dos status de cada exame de imagem               
    * @param o_exam_imag              Todos os exames do episódio
    * @param o_title_analy            Lista dos títulos com as descrições dos status de cada análise
    * @param o_title_drug             Lista dos títulos com as descrições dos status de cada prescrição
    * @param o_drug                   Todos os medicamentos do episódio
    * @param o_title_interv           Lista dos títulos com as descrições dos status de cada intervenção
    * @param o_intervention           Todas as intervenções do episódio
    * @param o_title_handoff          Título das notas de passagem de turno
    * @param o_handoff                Todas as notas de passagem de turno
    * @param o_patient                patient id
    * @param o_episode                episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/20
    *
    * @alter                          José Brito
    * @version                        1.1
    * @since                          2008/08/21
    **********************************************************************************************/
    FUNCTION get_grid_hand_off_det
    (
        i_lang          	IN language.id_language%TYPE,
        i_prof          	IN profissional,
        i_episode       	IN episode.id_episode%TYPE,
        i_patient       	IN patient.id_patient%TYPE,
		i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_diag          	OUT pk_types.cursor_type,
        o_sign_v        	OUT pk_types.cursor_type,
        o_title_analy   	OUT table_clob,
        o_analysis      	OUT table_clob,
        o_title_ex_imag 	OUT table_clob,
        o_exam_imag     	OUT table_clob,
        o_title_exams   	OUT table_clob,
        o_exams         	OUT table_clob,
        o_title_drug    	OUT table_clob,
        o_drug          	OUT table_clob,
        o_title_interv  	OUT table_clob,
        o_intervention  	OUT table_clob,
        o_hidrics       	OUT pk_types.cursor_type,
        o_allergies     	OUT pk_types.cursor_type,
        o_diets         	OUT pk_types.cursor_type,
        o_precautions   	OUT pk_types.cursor_type,
        o_icnp_diag     	OUT pk_types.cursor_type,
        --
        o_title_handoff OUT VARCHAR2,
        o_handoff       OUT pk_types.cursor_type,
        --
        o_patient OUT patient.id_patient%TYPE,
        o_episode OUT episode.id_episode%TYPE,
        o_sbar_note  OUT CLOB,
        o_title_sbar OUT VARCHAR2,
        o_id_epis_pn OUT epis_pn.id_epis_pn%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Hand off information for reports
    *                                                          
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis                   episode id
    * @param o_title_handoff          Hand off title
    * @param o_handoff                Hand off notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Spratley
    * @version                        2.6.0.3 
    * @since                          2010/08/04
    **********************************************************************************************/

    FUNCTION get_grid_hand_off_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        o_title_handoff OUT VARCHAR2,
        o_handoff       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Obter o detalhe de uma transferência de responsabilidade
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_epis_prof_resp         ID do prof q acede
    * @param o_epis_presp             Todos as transferências de responsabilidade do episódio (paciente)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/09/04
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_epis_presp     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Listagem das análises de um episódio por status(estado)
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_patient                patient id
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Títulos associados á descrição do estado da análise
    * @param o_analysis               Listas das análises
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/18
    **********************************************************************************************/
    FUNCTION get_epis_analy_det_stat
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN analysis_req.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_title    OUT table_clob,
        o_analysis OUT table_clob,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter as intervenções de um episódio por STATUS
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Lista dos títulos com as descrições dos status de cada intervenção
    * @param o_interv                 Listas dos procedimentos
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/17  
    **********************************************************************************************/
    FUNCTION get_interv_presc_status
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN interv_prescription.id_episode%TYPE,
        i_prof   IN profissional,
        o_title  OUT table_clob,
        o_interv OUT table_clob,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem dos exames de um episódio por status
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_patient                patient id    
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Lista dos títulos com as descrições dos status de cada exame de imagem
    * @param o_exam                   Lista dos exames de imagens
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/18  
    **********************************************************************************************/
    FUNCTION get_epis_exam_status
    (
        i_lang    IN language.id_language%TYPE,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_title   OUT table_clob,
        o_exam    OUT table_clob,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Listagem dos exames de IMAGEM de um episódio por status
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_patient                patient id    
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Lista dos títulos com as descrições dos status de cada exame de imagem
    * @param o_exam                   Lista dos exames de imagens
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @version                        1.0 
    * @since                          2008/06/04  
    **********************************************************************************************/
    FUNCTION get_epis_exam_images_status
    (
        i_lang    IN language.id_language%TYPE,
        i_epis    IN exam_req.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_title   OUT table_clob,
        o_exam    OUT table_clob,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_transfer
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_requested   IN VARCHAR2,
        i_trf_reason         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_clinical_service   IN NUMBER,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_transfer_no_commit
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_requested   IN VARCHAR2,
        i_trf_reason         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_clinical_service   IN NUMBER,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_transfer_status_list
    (
        i_lang              IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER,
        i_id_epis_prof_resp IN NUMBER,
        i_prof              IN profissional,
        i_flg_status        IN VARCHAR2,
        o_list              OUT pk_types.cursor_type,
        o_screen            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_transfer
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_id_epis_prof_resp  IN NUMBER,
        i_prof               IN profissional,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_accepted    IN VARCHAR2,
        i_trf_answer         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_cancel_notes       IN VARCHAR2,
        i_flg_status         IN VARCHAR2,
        i_id_room            IN NUMBER, -- ID DA SALA SUGERIDA
        i_id_bed             IN NUMBER, -- ID DA CAMA SUGERIDA
        i_flg_movement       IN VARCHAR2, -- QUER TRANSPORTE? Y/N
        i_type_mov           IN NUMBER, -- MACA, CADEIRA DE WHEELS, ...
        i_escort             IN VARCHAR2, -- ACOMPANHANTE
        i_id_dep_clin_serv   IN NUMBER, -- especialidade destino
        i_id_cancel_reason   IN epis_prof_resp.id_cancel_reason%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_transfer_no_commit
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_id_epis_prof_resp  IN NUMBER,
        i_prof               IN profissional,
        i_id_department_dest IN NUMBER,
        i_id_prof_dest       IN NUMBER,
        i_dt_trf_accepted    IN VARCHAR2,
        i_trf_answer         IN VARCHAR2,
        i_notes              IN VARCHAR2,
        i_cancel_notes       IN VARCHAR2,
        i_flg_status         IN VARCHAR2,
        i_id_room            IN NUMBER, -- ID DA SALA SUGERIDA
        i_id_bed             IN NUMBER, -- ID DA CAMA SUGERIDA
        i_flg_movement       IN VARCHAR2, -- QUER TRANSPORTE? Y/N
        i_type_mov           IN NUMBER, -- MACA, CADEIRA DE WHEELS, ...
        i_escort             IN VARCHAR2, -- ACOMPANHANTE
        i_id_dep_clin_serv   IN NUMBER, -- especialidade destino  
        i_id_cancel_reason   IN epis_prof_resp.id_cancel_reason%TYPE,
        i_dt_trf_end         IN VARCHAR2 DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_end_transfer
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_episode        IN NUMBER,
        i_id_movement       IN NUMBER,
        i_id_dep_clin_serv  IN NUMBER,
        i_transfer_movement IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_id_bed            IN bed.id_bed%TYPE DEFAULT NULL,
        i_dt_end_transfer   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * EXECUTE_TRANSFER_INT
    * 
    * @param i_lang                   the id language
    * @param i_id_episode             Episode Id
    * @param i_id_patient             Patient Id
    * @param i_prof                   professional, software and institution ids
    * @param i_id_department_orig     Id department origin   
    * @param i_id_department_dest     Id department destiny
    * @param i_id_dep_clin_serv       Id dep_clin_serv
    * @param i_trf_reason             Id reason for transfer
    * @param i_id_bed                 Bed ID
    * 
    * @param i_id_epis_prof_resp      Epis_prof_resp ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luís Maia
    * @version                        2.5.0.7.8
    * @since                          2010/Mar/15
    **********************************************************************************************/
    FUNCTION execute_transfer_int
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_dep_clin_serv   IN NUMBER,
        i_trf_reason         IN VARCHAR2,
        i_id_bed             IN bed.id_bed%TYPE,
        i_dt_transfer        IN VARCHAR2,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * EXECUTE_TRANSFER_INT
    * 
    * @param i_lang                   the id language
    * @param i_id_episode             Episode Id
    * @param i_id_patient             Patient Id
    * @param i_prof                   professional, software and institution ids
    * @param i_id_department_orig     Id department origin   
    * @param i_id_department_dest     Id department destiny
    * @param i_id_dep_clin_serv       Id dep_clin_serv
    * @param i_trf_reason             Id reason for transfer
    *
    * @param  o_id_epis_prof_resp     ID epis_prof_resp
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0
    * @since                          02-05-2007
    **********************************************************************************************/
    FUNCTION execute_transfer
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER,
        i_id_dep_clin_serv   IN NUMBER,
        i_trf_reason         IN VARCHAR2,
        i_flg_patient_consent IN epis_prof_resp.flg_patient_consent%TYPE DEFAULT NULL,
        o_id_epis_prof_resp  OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_transfer_detail_exec
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN NUMBER,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_alert
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_resp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the professional has permission to request a physician hand off.
    * Only applies to the CREATE button. The permission for other buttons (Ok/Cancel)
    * is returned in GET_EPIS_PROF_RESP_ALL.
    *
    * @param   I_LANG               Language associated to the professional executing the request
    * @param   I_PROF               Professional, institution and software ids
    * @param   i_episode            Episode ID
    * @param   i_flg_type           Categoria do profissional: S - Assistente social; D - Médico; N - Enfermeiro
    * @param   o_flg_create         Request permission: Y - yes, N - No
    * @param   o_create_actions     Options to display in the CREATE button
    * @param   o_error              Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          18-08-2009
    *
    * @alter                          José Brito
    * @version                        2.5.0.7
    * @since                          23-10-2009
    **********************************************************************************************/
    FUNCTION get_hand_off_req_permission
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN category.flg_type%TYPE,
        o_flg_create     OUT VARCHAR2,
        o_create_actions OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the professional's preferred department / clinical service.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_episode                 Episode ID
    * @param i_dest_professional       Destination professional ID
    * @param i_flg_type                Type of transfer
    * @param i_handoff_type            Type of hand-off
    * @param i_handoff_nurse_config    Nurse hand-off configuration (department/clinical service)
    * @param o_id_clinical_service     Clinical service ID
    * @param o_id_department           Department ID
    * @param o_error_message           User error message to display
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           14-Nov-2011
    *
    **********************************************************************************************/
    FUNCTION get_preferred_prof_dcs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_dest_professional    IN professional.id_professional%TYPE,
        i_flg_type             IN epis_prof_resp.flg_type%TYPE,
        i_handoff_type         IN VARCHAR2,
        i_handoff_nurse_config IN VARCHAR2,
        o_id_clinical_service  OUT clinical_service.id_clinical_service%TYPE,
        o_id_department        OUT department.id_department%TYPE,
        o_error_message        OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get episode dep_clin_serv based on a specific time
    *
    * @param   I_LANG               Language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_EPISODE            Episode ID
    * @param   I_DT_TARGET          Date that we want to check 
    * @param   I_DT_TARGET_TSTZ     Date that we want to check in TSTZ (optional)
    *
    * @RETURN  episode id_dep_clin_serv
    *
    * @author  Sérgio Santos
    * @version 2.6.1
    * @since   18-05-2012
    *
    */
    FUNCTION get_epis_dcs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN movement.id_episode%TYPE,
        i_dt_target      IN VARCHAR2,
        i_dt_target_tstz IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN dep_clin_serv.id_dep_clin_serv%TYPE;
    --
    /********************************************************************************************
    * Returns the overall responsible for a patient
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    *
    * @param   o_id_prof_resp             ID of the responsible professional
    * @param   o_prof_resp_name           Name of the overall responsible professional
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         Sergio Dias
    * @version                        2.6.3.7.1
    * @since                          23-Aug-2013
    **********************************************************************************************/
    FUNCTION get_overall_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_id_prof_resp   OUT professional.id_professional%TYPE,
        o_prof_resp_name OUT professional.name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the episode responsible
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    *
    * @param   o_error                    Error message
    *                        
    * @return  Episode responsible ID
    * 
    * @author                         Sergio Dias
    * @version                        2.6.3.8.1
    * @since                          20-Sept-2013
    **********************************************************************************************/
    FUNCTION get_episode_responsible
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns professional responsible for patient
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_scope                    Scope - 'P'
    * @param   i_id_scope                 id - patient_id
    *
    *                        
    * @return  Episode responsible ID
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0
    * @since                          05-May-2014
    **********************************************************************************************/
    FUNCTION get_prof_resp_cda
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_scope    IN VARCHAR2,
        i_id_scope IN patient.id_patient%TYPE
    ) RETURN t_resp_professional_cda;

    /********************************************************************************************
    * Gets all professionals reponsibles by scope - 'P'- patient, 'E'- episode, 'V'- visit
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_scope                    Scope - 'P'- patient, 'E'- episode, 'V'- visit
    * @param   i_id_scope                 Scope identifier
    * @param   o_prof_resp                Information about professional responsibles
    * @param   o_error                    Error message
    *                        
    * @return  Cursor that contains professional name, id, institution and software 
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.2.1
    * @since                          16-OCT-2014
    **********************************************************************************************/
    FUNCTION get_prof_responsibles
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_scope     IN VARCHAR2,
        i_id_scope  IN patient.id_patient%TYPE,
        o_prof_resp OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_presc_cancel
    (
        i_lang               IN NUMBER,
        i_id_episode         IN NUMBER,
        i_id_patient         IN NUMBER,
        i_prof               IN profissional,
        i_id_department_orig IN NUMBER,
        i_id_department_dest IN NUMBER
    ) RETURN VARCHAR2;

    PROCEDURE set_transfer_alert
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_episode        IN NUMBER,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE
    );

    FUNCTION check_cur_service_resp
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_department_dest       IN epis_prof_resp.id_department_dest%TYPE,
        i_id_clinical_service_dest IN epis_prof_resp.id_clinical_service_dest%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the transfer responsability  location in a date(attending/ resident)
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_dt_transf  date
    * @param i_admission  in on admission (Y/N) 
    *
    * @return             Attending and Resident on that time
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01
    **********************************************************************************************/
    FUNCTION get_prof_resp_list_by_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_resp    IN epis_multi_prof_resp.dt_update%TYPE,
        i_admission  IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get all transfer responsability in a episode (attending/ resident)
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_id_episode episode idenfier
    *
    * @return             Type with the transfer responsability information (attending/ resident)
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01
    **********************************************************************************************/
    FUNCTION tf_get_responsability_transf
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_table_epis_transf;

    --############################################################################################## --
    --GLOBALS
    --############################################################################################## --
    --
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    g_owner        VARCHAR2(30 CHAR);
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;
    g_exception EXCEPTION;
    g_date_mask VARCHAR2(16) := 'YYYYMMDDHH24MISS';
    g_yes       VARCHAR2(1);
    g_no        VARCHAR2(1);
    --
    g_epis_active   episode.flg_status%TYPE;
    g_epis_inactive episode.flg_status%TYPE;
    g_epis_diag_act episode.flg_status%TYPE;
    --
    g_hand_off_r epis_prof_resp.flg_status%TYPE;
    g_hand_off_c epis_prof_resp.flg_status%TYPE;
    g_hand_off_d epis_prof_resp.flg_status%TYPE;
    g_hand_off_f epis_prof_resp.flg_status%TYPE;
    g_hand_off_x epis_prof_resp.flg_status%TYPE;
    g_hand_off_t epis_prof_resp.flg_status%TYPE;
    g_hand_off_i epis_prof_resp.flg_status%TYPE; -- In transit
    --
    g_no_triage            VARCHAR2(200);
    g_no_triage_color_text VARCHAR2(200);
    g_color_rank           triage_color.rank%TYPE;
    g_id_no_triage         triage_color.id_triage_color%TYPE;
    --
    g_software_inp  software.id_software%TYPE;
    g_software_edis software.id_software%TYPE;
    g_software_ubu  software.id_software%TYPE;
    --
    g_epis_type     episode.id_epis_type%TYPE;
    g_diag_flg_type epis_diagnosis.flg_type%TYPE;
    --
    g_flg_resp_g VARCHAR2(1);
    g_flg_resp_h VARCHAR2(1);
    --
    g_flg_type_s VARCHAR2(1);
    g_flg_type_d VARCHAR2(1);
    g_flg_type_n VARCHAR2(1);
    g_flg_type_q VARCHAR2(1);
    --

    g_interv_plan_pend  interv_presc_plan.flg_status%TYPE;
    g_interv_plan_canc  interv_presc_plan.flg_status%TYPE;
    g_interv_plan_req   interv_presc_plan.flg_status%TYPE;
    g_interv_plan_admt  interv_presc_plan.flg_status%TYPE;
    g_interv_plan_nadmt interv_presc_plan.flg_status%TYPE;
    g_interv_plan_final interv_presc_plan.flg_status%TYPE;
    g_interv_plan_ext   interv_presc_plan.flg_status%TYPE;
    --
    g_interv_type_nor interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_sos interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_uni interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_ete interv_presc_det.flg_interv_type%TYPE;
    g_interv_type_con interv_presc_det.flg_interv_type%TYPE;
    --
    g_exam_type       VARCHAR2(1);
    g_exam_type_ortho exam.flg_type%TYPE;
    g_exam_type_aud   exam.flg_type%TYPE;
    g_exam_type_pf    exam.flg_type%TYPE;
    g_exam_type_gas   exam.flg_type%TYPE;
    g_image_exam_type exam.flg_type%TYPE;
    g_exam_det_req    exam_req_det.flg_status%TYPE;
    g_exam_det_read   exam_req_det.flg_status%TYPE;
    g_exam_det_pend   exam_req_det.flg_status%TYPE;
    g_exam_det_exec   exam_req_det.flg_status%TYPE;
    g_exam_det_final  exam_req_det.flg_status%TYPE;
    --
    g_analy_req_det_status sys_domain.code_domain%TYPE;
    g_exam_req_det_status  sys_domain.code_domain%TYPE;
    g_interv_det_status    sys_domain.desc_val%TYPE;
    g_drug_stat_canc       sys_domain.val%TYPE;
    g_exam_stat_canc       sys_domain.val%TYPE;
    --
    g_analy_req_det_canc  analysis_req_det.flg_status%TYPE;
    g_analy_req_det_req   analysis_req_det.flg_status%TYPE;
    g_analy_req_det_pend  analysis_req_det.flg_status%TYPE;
    g_analy_req_det_read  analysis_req_det.flg_status%TYPE;
    g_analy_req_det_exec  analysis_req_det.flg_status%TYPE;
    g_analy_req_det_final analysis_req_det.flg_status%TYPE;
    --
    g_ed_flg_status_d  epis_diagnosis.flg_status%TYPE;
    g_ed_flg_status_co epis_diagnosis.flg_status%TYPE;
    g_trf_requested    VARCHAR2(0050);
    g_transfer_n       VARCHAR2(1);
    g_transfer_y       VARCHAR2(1);
    --
    g_mov_status_transp movement.flg_status%TYPE;
    --
    g_flg_transf_i    VARCHAR2(1 CHAR);
    g_flg_transf_s    VARCHAR2(1 CHAR);
    g_flg_transf_o    VARCHAR2(1 CHAR);
    g_flg_transf_a    VARCHAR2(1 CHAR);
    g_flg_anamnesis_c VARCHAR2(1);
    g_flg_unknown_y   VARCHAR2(1);
    --
    g_handoff_nurse_clin_serv  VARCHAR2(2);
    g_handoff_nurse_department VARCHAR2(1);
    --
    g_prof_cat_doc VARCHAR2(1);
    g_prof_cat_nrs VARCHAR2(1);

    g_exam_type_req         CONSTANT ti_log.flg_type%TYPE := 'ER';
    g_exam_type_det         CONSTANT ti_log.flg_type%TYPE := 'ED';
    g_analysis_type_req_det CONSTANT ti_log.flg_type%TYPE := 'AD';

    g_flg_ehr_normal   CONSTANT VARCHAR2(1) := 'N';
    g_flg_ehr_schedule CONSTANT VARCHAR2(1) := 'S';

    g_handoff_normal   CONSTANT VARCHAR2(1) := 'N';
    g_handoff_multiple CONSTANT VARCHAR2(1) := 'M';

    g_cons_cs CONSTANT VARCHAR2(2) := 'CS';

    g_patient_scope CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_visit_scope   CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_episode_scope CONSTANT VARCHAR2(1 CHAR) := 'E';

END pk_hand_off;
/