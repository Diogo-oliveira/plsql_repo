/*-- Last Change Revision: $Rev: 2028712 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hand_off_ux IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 01-10-2010 09:15:09
    -- Purpose : Hand off functions used by flash

    -- Public function and procedure declarations

    /**********************************************************************************************
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_all
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets responsability history
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_epis_prof_resp  Epis prof resp id
    * @param   o_resp_hist       Responsability history grid
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_epis_prof_resp_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_resp_hist      OUT pk_types.cursor_type,
        o_sbar_note      OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_prof_resp
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN epis_info.id_episode%TYPE,
        o_show_msg_box         OUT VARCHAR2,
        o_flg_hand_off_type    OUT VARCHAR2,
        o_responsibles         OUT pk_types.cursor_type,
        o_overall_resp_box     OUT pk_types.cursor_type,
        o_episode_resp_options OUT pk_types.cursor_type,
        o_labels_grid          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the available tabs when selecting the overall responsible
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_episode         Episode id
    * @param   i_patient         Patient id
    * @param   o_tabs            Available tabs
    * @param   o_error           Error information
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_overall_resp_tabs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_tabs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
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
    * Returns the options to display in the hand-off internal button, 
    * for the ACTIONS/VIEWS buttons.
    *
    * This method is not intended to set permissions for each option. Insted this will be managed
    * by Flash according to the values of flags embedded in the cursors returned by GET_EPIS_PROF_RESP_ALL.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_flg_type                 Context of hand-off: physician or nurse hand-off
    * @param   o_id_epis_multi_prof_resp  New multiple hand-off record
    * @param   o_error                    Error message
    *                        
    * @return  TRUE. FALSE on error.
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          18-10-2010
    **********************************************************************************************/
    FUNCTION get_hand_off_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_prof_resp.flg_type%TYPE,
        o_actions  OUT pk_types.cursor_type,
        o_views    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Current professional is taking EPISODE responsability over the patient.
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_prof_to                Destination professional ID   
    * @param i_id_episode             Destination Episode ID
    * @param i_notes                  Hand-off notes
    * @param i_prof_cat               Professional category: S - Social assistant; D - Physician; N - Nurse
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/21
    **********************************************************************************************/
    FUNCTION set_my_epis_responsability
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_to    IN professional.id_professional%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_notes      IN epis_prof_resp.notes_clob%TYPE,
        i_prof_cat   IN epis_prof_resp.flg_type%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg_body   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a new request for EPISODE responsability (transfer responsability).
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_prof_to                Array of destination professionals
    * @param i_tot_epis               Array with total number of transferred episodes
    * @param i_epis_pat               Array with episode ID's
    * @param i_cs_or_dept             Array with destination clinical services/departments
    * @param i_notes                  Array with transfer notes
    * @param i_flg_type               Type of request: (D) Physician transfer (N) Nurse transfer
    * @param i_flg_profile            Type of profile (when applicable): (S)pecialist (R)esident (I)ntern (N)urse
    * @param i_id_speciality          Destination speciality ID (when applicable(
    * @param i_flg_assign_supervisor  Flag that indicates if this is a supervisor assignment
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/21
    **********************************************************************************************/
    FUNCTION set_req_epis_responsability
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_to               IN table_varchar,
        i_tot_epis              IN table_number,
        i_epis_pat              IN table_number,
        i_cs_or_dept            IN table_number,
        i_notes                 IN table_varchar,
        i_flg_type              IN epis_prof_resp.flg_type%TYPE,
        i_flg_profile           IN profile_template.flg_profile%TYPE,
        i_id_speciality         IN epis_multi_prof_resp.id_speciality%TYPE,
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        i_sbar_note             IN CLOB DEFAULT NULL,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * List all the specialities with an assigned specialist physician.
    * 
    * NOTE: Used only for OVERALL responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_profs                  cursor with types departament or clinical service
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                        2.6.0.4 
    * @since                          2010/10/19
    **********************************************************************************************/
    FUNCTION get_handoff_dest_overall
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_profs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Lista serviços clinicos, ou departamentos, para filtrar profissionais para os quais o profissional 
      actual pode transferir a responsabilidade de pacientes seus.
    * 
    * NOTE: Used only for EPISODE responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               tipo de transferência: D - médico, N - enfermeiro
    * @param o_dests_header           cabeçalho da coluna dos destinos
    * @param o_profs_header           cabeçalho da coluna dos profissionais
    * @param o_dests                  cursor with types departament or clinical service
    * @param o_handoff_type           type of hand-off configured in the institution
    * @param o_handoff_nurse          configuration for nurse hand-off (clinical service or department)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2007/06/05
    *
    * @alter                          José Brito
    * @version                        2.6.0.4 
    * @since                          2010/10/19
    **********************************************************************************************/
    FUNCTION get_handoff_dest
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN category.flg_type%TYPE,
        o_dests_header  OUT VARCHAR2,
        o_profs_header  OUT VARCHAR2,
        o_dests         OUT pk_types.cursor_type,
        o_handoff_type  OUT sys_config.value%TYPE,
        o_handoff_nurse OUT sys_config.value%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the profile types (Specialist, Resident, Intern, Nurse, etc.)
    * to which the professional can make a hand-off request.
    *
    * NOTE: Used only for EPISODE responsability. 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_flg_type               type of category (D) Physician (N) Nurse
    * @param o_profiles               list of profile types
    * @param o_error                  error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profiles
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN category.flg_type%TYPE,
        o_profiles   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the destination professionals for the current responsability transfer, filtered
    * according to the destination clinical service/department/speciality.
    *
    * Used for EPISODE responsability.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_dest                   ID of the destination clinical service/department/speciality
    * @param i_episode                Episode ID
    * @param i_flg_type               Type of category (D) Physician (N) Nurse
    * @param i_handoff_type           Type of hand-off: (N) Normal (M) Multiple
    * @param i_handoff_nurse          Configuration for nurse hand-off (clinical service or department)
    * @param i_flg_profile            Type of profile (specialist, resident, intern, nurse)
    * @param i_flg_assign_supervisor  Flag that indicates if this is a supervisor assignment
    * @param o_profs                  List of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    *
    * @alter                          José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dest_profs
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_dest                  IN dep_clin_serv.id_clinical_service%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_type              IN category.flg_type%TYPE,
        i_handoff_type          IN VARCHAR2,
        i_handoff_nurse         IN VARCHAR2,
        i_flg_profile           IN profile_template.flg_profile%TYPE,
        i_flg_assign_supervisor IN VARCHAR2 DEFAULT 'N',
        o_profs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the destination specialist physicians for the current responsability transfer.
    * Used for OVERALL responsability.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_dest                   ID of the destination clinical service/department/speciality
    * @param i_episode                Episode ID
    * @param o_profs                  List of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.5.0.7
    * @since                          2009/10/07
    *
    * @alter                          José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_dest_ov_profs
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_dest    IN dep_clin_serv.id_clinical_service%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns all data relative to on-call physicians to display in the overall 
    * responsability transfer screen.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_episode             Episode ID
    * @param o_profs                  List of on-call physicians
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/10/22
    **********************************************************************************************/
    FUNCTION get_handoff_oncall_profs_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_profs      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          07-10-2010
    **********************************************************************************************/
    FUNCTION set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Terminate responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_epis_prof_resp        Responsability transfer request ID
    * @param   i_flg_type                 Type of hand-off: Physician / Nurse
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION set_terminate_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type          IN epis_prof_resp.flg_type%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set main overall responsability for a patient.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_new_resp              New main overall responsible ID
    * @param   i_id_epis_prof_resp        Hand-off request ID
    * @param   o_flg_show                 Show warning message? Y/N
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message text
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          11-10-2010
    **********************************************************************************************/
    FUNCTION set_main_resp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_new_resp       IN professional.id_professional%TYPE,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a responsability request.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          04-11-2010
    **********************************************************************************************/
    FUNCTION cancel_request_resp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Change the status of the hand-off requests (CANCEL, ACCEPT or REJECT).
    * Function called by the Flash layer.
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

    /**
    * Get patient previous responsibles
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param o_profs                  List of on-call physicians ID's
    * @param o_error                  Error message
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_previous_responsibles
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get hand off configuration vars
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional, software and institution ids
    * @param i_flg_type               Transf. type
    * @param o_label                  Speciality or Clinical Service or Department
    * @param o_handoff_type           Hand off type
    * @param o_error                  Error message
    *
    * @value   i_flg_type     {*} 'D' Physician
    *                         {*} 'N' Nurse
    *
    * @value   o_handoff_type {*} 'N' Normal
    *                         {*} 'M' Multiple
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.4
    * @since   29-09-2010
    */
    FUNCTION get_hand_off_vars
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN category.flg_type%TYPE,
        o_label        OUT sys_message.code_message%TYPE,
        o_handoff_type OUT sys_config.value%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the information of the given episode
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

    /********************************************************************************************
    * Cancel a responsability.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_epis_prof_resp           Record ID
    * @param   i_flg_type                 Type of transfer: (D) Physician (N) Nurse
    * @param   i_notes                    Cancellation notes
    * @param   i_id_cancel_reason         Cancel reason ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE/FALSE
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1
    * @since                          07-06-2011
    **********************************************************************************************/
    FUNCTION cancel_responsability
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_prof_resp   IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_flg_type         IN epis_prof_resp.flg_type%TYPE,
        i_notes            IN epis_prof_resp.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates overall responsability over an episode.
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_prof_resp             Responsible professional
    * @param   i_id_speciality            Responsible professional speciality ID
    * @param   i_notes                    Responsability record notes
    * @param   i_flg_epis_respons         Flag that indicates if the professional also takes episode responsability 
    * @param   o_flg_show                 Show warning message (Y) Yes (N) No
    * @param   o_msg_title                Warning message title
    * @param   o_msg_body                 Warning message body
    * @param   o_id_epis_prof_resp        Responsability record ID
    * @param   o_id_epis_multi_prof_resp  Multiple responsability record ID
    * @param   o_error                    Error message
    *                        
    * @return  TRUE if successfull / FALSE otherwise
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.10.1
    * @since                          27-Set-2012
    **********************************************************************************************/
    FUNCTION set_overall_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_prof_resp            IN epis_multi_prof_resp.id_professional%TYPE,
        i_id_speciality           IN epis_multi_prof_resp.id_speciality%TYPE,
        i_notes                   IN epis_prof_resp.notes_clob%TYPE,
        i_flg_epis_response        IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_body                OUT VARCHAR2,
        o_id_epis_prof_resp       OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_id_epis_multi_prof_resp OUT epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_first_nurse_resp         Episode first nurse responsible
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_resp_doctor_nurse
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT professional.id_professional%TYPE,
        o_first_nurse_resp OUT professional.id_professional%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF HEADER FUNCTION PK_HEA_PRV_EPIS.GET_EPIS_RESPONSIBLES
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    * @param   i_id_patient               Patient ID
    * @param   o_resp_doctor              Episode responsible physician
    * @param   o_resp_doctor_spec         Responsible physician speciality
    * @param   o_resp_nurse               Episode responsible nurse
    * @param   o_error                    Error message
    *                        
    * @return  Array with the responsible professionals ID
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          01-Fev-2013
    **********************************************************************************************/
    FUNCTION get_epis_responsibles
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT VARCHAR,
        o_resp_doctor_spec OUT VARCHAR,
        o_resp_nurse       OUT VARCHAR,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * THIS FUNCTION IS ONLY TO BE USED BY REPORTS TEAM
    * HAS THE SAME LOGIC OF FUNCTION GET_EPIS_PROF_RESP_ALL BUT ALSO CHECKS IN EPIS_INFO FOR OUTP
    * Listing of all transfers of responsibility made about the patient (episode)
    *
    * @param   i_lang                 Language id
    * @param   i_prof                 Professional, software and institution ids
    * @param   i_episode              Episode id
    * @param   i_flg_type             Professional Category
    * @param   i_flg_hist             Get history responsability?
    * @param   o_resp_grid            Responsability grid
    * @param   o_transf_grid          Transfer requests grid
    * @param   o_error                Error message
    *
    * @value   i_flg_hist     {*} 'Y' Returns history responsability grid
    *                         {*} 'N' Returns current responsability grid
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author  Sergio Dias
    * @version v2.6.3.8.3
    * @since   17-Oct-2013
    **********************************************************************************************/
    FUNCTION get_responsibles
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_type    IN category.flg_type%TYPE,
        i_flg_hist    IN VARCHAR2,
        o_resp_grid   OUT pk_types.cursor_type,
        o_transf_grid OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of professional responsible for admission (doctors)
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional information data
    * @param   i_episode                  Episode identifier
    * @param   o_prof_resp                List od professional responsible for episode                   
    * @return  true/faslse
    * 
    * @author                         Elisabete Bugalho            
    * @version                        2.7.1.0
    * @since                          28/04/2017
    **********************************************************************************************/
    FUNCTION get_epis_prof_resp_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_prof_resp OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_hand_off_ux;
/