/*-- Last Change Revision: $Rev: 1854219 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2018-07-13 12:06:10 +0100 (sex, 13 jul 2018) $*/
CREATE OR REPLACE PACKAGE pk_problems_ux IS
    /**
    * Registers a review for a problem.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_pat_problem  problem id
    * @param i_flg_source      FLAG SOURCE
    * @param i_review_notes    review notes (optional)
    * @param i_EPISODE         episode identifier
    * @param I_FLG_AUTO        FLAG AUTO Y/N
    *
    * @param o_error           error message 
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_source     IN table_varchar,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_problem                Cursor containing the original problem
    * @param o_problem_hist           table_table_varchar containing the problem's changes
    * @param o_review_hist            cursor containing review list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_pat_problem_det_new_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem_det_new_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get problem deteail
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               probblem identifier
    * @param i_type                   Patient ID
    * @param i_prof                   object (professional ID, institution ID, software ID)
    * @param i_flg_area               Parameter exists only for audit-trail purposes
    * @param o_problem                out cursor
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_pat_problem_det
    
    (
        i_lang     IN language.id_language%TYPE,
        i_pat_prob IN pat_problem.id_pat_problem%TYPE,
        i_type     IN VARCHAR2,
        i_prof     IN profissional,
        i_flg_area IN pat_history_diagnosis.flg_area%TYPE,
        o_problem  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem_det
    
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_flg_area     IN pat_history_diagnosis.flg_area%TYPE,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels a specific problem in the Problems functionality
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    * @param i_id_episode             Episode ID
    * @param i_id_problem             The problem ID 
    * @param i_type                   Type of problem 
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes
    * @param i_prof_cat_type          Professional category flag
    * @param i_flg_area               Parameter exists only for audit-trail purposes
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION cancel_pat_problem
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN pat_problem.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_problem       IN NUMBER,
        i_type             IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_flg_area         IN pat_history_diagnosis.flg_area%TYPE,
        o_type             OUT table_varchar,
        o_ids              OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get_pat_problem_report
    *
    * @param i_lang                   Language ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode 
    * @param i_report
    * @param o_pat_problem            Cursor containing the problems
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/

    FUNCTION get_pat_problem_report
    (
        i_lang                 IN language.id_language%TYPE,
        i_pat                  IN pat_problem.id_patient%TYPE,
        i_prof                 IN profissional,
        i_episode              IN pat_problem.id_episode%TYPE,
        i_report               IN VARCHAR2,
        i_dt_ini               IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_pat_problem          OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_pat_problem_hie
    *
    * @param i_lang                   Language ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode 
    * @param i_report
    * @param o_pat_problem            Cursor containing the problems
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/

    FUNCTION get_pat_problem_hie
    (
        i_lang                 IN language.id_language%TYPE,
        i_pat                  IN pat_problem.id_patient%TYPE,
        i_prof                 IN profissional,
        i_episode              IN pat_problem.id_episode%TYPE,
        i_report               IN VARCHAR2,
        i_dt_ini               IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_pat_problem          OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * create_pat_problem_array
    *
    * @param i_lang               language identifier  
    * @param i_epis               episode identifier  
    * @param i_pat                patient identifier
    * @param i_prof               professional identifier
    * @param i_desc_problem       problem descriptions
    * @param i_flg_status         status flag
    * @param i_notes              notes
    * @param i_dt_symptoms        onset date
    * @param i_epis_anamnesis     ???
    * @param i_prof_cat_type      professional category
    * @param i_diagnosis          id diagnosis
    * @param i_flg_nature         nature flag
    * @param i_alert_diag         alert diagnosis
    * @param i_dt_resolution      resolution date
    * @param i_precaution_measure precausion measures
    * @param i_header_warning     header warning
    * @param i_cdr_call           clinical decision rule corresponding id
    * @param i_flg_area - Indentifies the area to which the record belongs: H-Past Medical History; P -Problems
    * @param o_msg                
    * @param o_msg_title         
    * @param o_flg_show          
    * @param o_button
    * @param o_error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_call.id_cdr_call%TYPE,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /* create patient problems with episode group and seq num */
    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_call.id_cdr_call%TYPE,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        i_flg_epis_prob          IN VARCHAR2,
        i_prob_group             IN table_number DEFAULT NULL,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Removes a problem from the list of problems registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION set_unregistered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Add a problem to the list of problems registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION set_registered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
    *       OBJECTIVO: Alterar / cancelar problema do doente.
    *              Usada no ecrã de mudança de estado dos "Problemas" do doente, pq 
    *            permite a mudança de estado de vários problemas em simultâneo.
    *       PARAMETROS:  Entrada: 
    * @param I_LANG - Language id
    * @param I_PAT - ID do doente 
    * @param I_PROF - profissional q regista 
    * @param I_ID_PAT_PROBLEM - array de IDs de registos alterados 
    * @param I_FLG_STATUS - array de estados 
    * @param I_NOTES - array de notas  
    * @param I_TYPE - array de tipos: P - problemas, A - alergias, H - hábitos 
    * @param I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param i_flg_area - Indentifies the area to which the record belongs: H-Past Medical History; P -Problems
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **/
    FUNCTION set_pat_problem_array_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /* set patient problems with episode group and seq num */
    FUNCTION set_pat_problem_array_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        i_flg_epis_prob          IN VARCHAR2,
        i_prob_group             IN table_number,
        i_seq_num                IN table_number,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *           OBJECTIVO: Alterar / cancelar problema do doente.
    *                  Usada no ecrã de mudança de estado dos "Problemas" do doente, pq 
    *                permite a mudança de estado de vários problemas em simultâneo.
    * @param I_LANG - Language id
    * @param I_PAT - ID do doente                      
    * @param I_PROF - profissional q regista                      
    * @param I_ID_PAT_PROBLEM - array de IDs de registos alterados                      
    * @param I_FLG_STATUS - array de estados                      
    * @param I_NOTES - array de notas                       
    * @param I_TYPE - array de tipos: P - problemas, A - alergias, H - hábitos                      
    * @param I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **/
    FUNCTION set_pat_problem_array
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_dt_resolution         IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_resolved           IN table_varchar,
        i_dt_resolved_precision IN table_varchar,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /* set patient problems with episode group and seq num */
    FUNCTION set_pat_problem_array
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_dt_resolution         IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_resolved           IN table_varchar,
        i_dt_resolved_precision IN table_varchar,
        i_flg_epis_prob         IN VARCHAR2,
        i_prob_group            IN table_number,
        i_seq_num               IN table_number,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * problem grid
    *
    * @param i_lang        language identifier       
    * @param i_pat         patient identifier   
    * @param i_status      flag status   
    * @param i_type        type   
    * @param i_prof        professional identifier   
    * @param i_problem     problem identifier   
    * @param i_episode     episode identifier   
    * @param i_report      report flag   
    * @param o_pat_problem   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * problem grid
    *
    * @param i_lang        language identifier       
    * @param i_pat         patient identifier   
    * @param i_status      flag status   
    * @param i_type        type   
    * @param i_prof        professional identifier   
    * @param o_pat_problem   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * problem grid
    *
    * @param i_lang        language identifier       
    * @param i_pat         patient identifier   
    * @param i_status      flag status   
    * @param i_type        type   
    * @param i_prof        professional identifier   
    * @param i_problem     problem identifier   
    * @param o_pat_problem   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the problems onset list
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_onset                  Onset list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_problems_onset_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_onset OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *           OBJECTIVO:   Obter estados poss para um problema
    * @param I_LANG - Language id
    * @param I_PROF - Profissional                Saida:   
    * @param O_PROBLEM_PROT - Lista de protocolos possíveis                            
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    ***/
    FUNCTION get_problem_protocol
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN pat_history_diagnosis.flg_area%TYPE,
        o_problem_prot OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get nature field options.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_nat          nature field options
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/07/04
    */
    FUNCTION get_nature_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_nat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obter naturezas possíveis para um problema
    * @param I_LANG - Language id 
    * @param I_PROF - Profissional
    * @param O_PROBLEM_NATURE - Na   
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **/
    FUNCTION get_problem_nature
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_nature OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obter lista de diagnósticos. se I_ID_PARENT for null, devolve os diagnósticos,
    *       senão devolve todos os diagnósticos "filhos" do seleccionado.    
    * @param I_LANG - Language id
    * @param I_ID_PARENT - ID do diagnóstico "pai" seleccionado
    * @param I_PATIENT - ID do doente                                       
    * @param I_FLG_TYPE - Tipo: D - ICD9, P - ICPC2, C - ICD9 CM 
    * @param I_SEARCH - valor do critério de pesquisa      
    * @param O_LIST - array de diagn?cos                       
    * @param O_ERROR - erro 
    *         
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_problem_list
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_flg_type  IN diagnosis.flg_type%TYPE,
        i_search    IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the possible precautions available
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param o_precautions     Cursor containing the precautions
    * @param o_error           error message 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_precaution_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_precautions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns the information of a specific problem. The problem can be in problems and relevant diseases.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    * @param i_id_problem             The problem ID 
    * @param i_type                   Type of records wanted (P - problems, D - relevant diseases)
    * @param o_pat_problem            Cursor containing the problem information
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_pat_problem_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_problem.id_patient%TYPE,
        i_id_problem  IN NUMBER,
        i_type        IN VARCHAR2,
        o_pat_problem OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Search all diagnosis on the DIAGNOSIS table
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_criteria               String to search
    * @param i_diag_parent            Diagnosis parent, if it exists
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param i_prof                   Professional object
    * @param i_flg_task_type          Task Type Flag - sys_domain 'PAT_HISTORY_DIAGNOSIS.FLG_AREA'
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/

    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_criteria      IN VARCHAR2,
        i_diag_parent   IN diagnosis.id_diagnosis_parent%TYPE,
        i_flg_type      IN diagnosis.flg_type%TYPE,
        i_prof          IN profissional,
        i_flg_task_type IN VARCHAR2,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_criteria    IN VARCHAR2,
        i_diag_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_flg_type    IN diagnosis.flg_type%TYPE,
        i_prof        IN profissional,
        o_diagnosis   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Multitype diagnoses search. Based on GET_DIAGNOSIS.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_type     diagnosis types flags
    * @param i_diag_parent  parent diagnosis identifier
    * @param i_criteria     user query
    * @param i_format_text  apply styles to diagnoses names? Y/N
    * @param o_diagnosis    diagnoses data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.6.1
    * @since                2011/01/19
    */
    FUNCTION get_diagnosis_mt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN table_varchar,
        i_diag_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_criteria    IN VARCHAR2,
        i_format_text IN VARCHAR2,
        o_diagnosis   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * get_problem_status
    *
    * @param i_lang        language identifier       
    * @param i_prof        professional identifier   
    * @param i_status      flag status   
    *
    * @param o_problem_status   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_problem_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_status OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns add button options
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param o_list                  add list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/31
    **********************************************************************************************/
    FUNCTION get_add_problems
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * insert patient problem unawareness
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier
    * @param      i_id_prob_unaware    problem unawareness identifier
    * @param      i_id_patient         patient identifier
    * @param      i_id_episode         episode identifier
    * @param      i_notes              notes
    * @param      i_flg_status         flag status
    * @param      i_id_cancel_reason   cancel reason identifier
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_id_combination_spec  combination specification identifier  
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION ins_pat_prob_unaware
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prob_unaware     IN pat_prob_unaware.id_prob_unaware%TYPE,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_flg_status          IN pat_prob_unaware.flg_status%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get patient problem unawareness choices
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param o_choices                choices list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/02/01
    **********************************************************************************************/
    FUNCTION get_pat_prob_unaware_choices
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_choices  OUT pk_types.cursor_type,
        o_notes    OUT pat_prob_unaware.notes%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get patient problem unawareness choices
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param i_episode                episode id
    * @param o_title                  title
    * @param o_msg                    message
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/02/01
    **********************************************************************************************/
    FUNCTION validate_unawareness
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_prob_unaware IN pat_prob_unaware.id_prob_unaware%TYPE,
        o_title           OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_show            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate if problem is a trial
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_diagnosis              diagnosis
    * @param o_title                  title
    * @param o_msg                    message
    * @param o_flg_show               show popup Y or N
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Elisabete Bugalho
    * @version               2.6.1
    * @since                 2011/03/03
    **********************************************************************************************/
    FUNCTION validate_trials
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN table_number,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_shortcut  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the area option that will appear in the problems edition screen that allow to switch the
    * area of the record (Problems, PAst medical history)
    *
    * @param      i_lang               Language id
    * @param      i_prof               profissional identifier
    * @param      i_id_record          Record identifier, if not null, this means the function was called during an edit action
    * @param      o_list               List with the available area
    *
    * @param      o_error              mensagem de erro
    *
    * @author  Sofia Mendes
    * @version 2.6.3.2.1
    * @since   13-Feb-2013
    **********************************************************************************************/
    FUNCTION get_areas_domain
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_record         IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        id_tl_task_timeline IN tl_task.id_tl_task%TYPE DEFAULT NULL,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************************************
    * During a problem creation, validates if the selected diagnoses can remain selected when changing to a different type
    *
    * @param      i_lang                Language id
    * @param      i_prof                profissional identifier
    * @param      i_id_patient          Patient ID
    * @param      i_flg_area            Indicates the type of problem to which the user just changed (past_history_diagnosis.flg_area)
    * @param      i_id_diagnosis        Selected diagnoses id list
    * @param      i_id_alert_diagnosis  Selected alert_diagnoses id list
    * @param      o_id_diagnosis        Diagnoses id list that can remain selected
    * @param      o_id_alert_diagnosis  Alert_diagnoses id list that can remain selected
    *
    * @param      o_error              error message
    *
    * @author     Sergio Dias
    * @version    2.6.3.12
    * @since      10-Mar-2013
    ************************************************************************************************************************/
    FUNCTION validate_diagnosis_selection
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_area           IN pat_history_diagnosis.flg_area%TYPE,
        i_id_diagnosis       IN table_number,
        i_id_alert_diagnosis IN table_number,
        o_id_diagnosis       OUT table_number,
        o_id_alert_diagnosis OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN pat_history_diagnosis.id_patient%TYPE,
        i_type        IN VARCHAR2,
        i_id          IN NUMBER,
        i_id_episode  IN pat_problem.id_episode%TYPE,
        o_pat_problem OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the the place of occurence of the diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Diagnosis ID
    * @param i_id_location            Place of occurence ID already registered 
     *
    * @return                         Place of occurence
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          17/11/2016
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_id_location IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the the places of occurence of the diagnoses
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Collection of diagnoses IDs
    * @param i_id_location            Collection of places of occurence (IDs already registered)
    *
    * @return                         Places of occurence
    *
    * Note: This function will return the locations that are common to all the input diagnoses.
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN table_number,
        i_id_location IN table_number DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;	

    /************************************************************************************************************************
    * set_epis_problem_group_array
    *
    * @param i_lang The language id
    * @param i_episode The episode id
    * @param i_prof The professional, institution and software ids
    * @param i_id_pat_problem An array with pat problem ids
    * @param i_prob_group  An array with group ids
    * @param i_seq_num An array with rank ids
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/8
    **********************************************************************************************/
    FUNCTION set_epis_problem_group_array
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_id_problem     IN table_number,
        i_pre_id_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_prob_group     IN table_number,
        i_seq_num        IN table_number,
        i_flg_type       IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * set_epis_prob_group_note
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_id_epis_prob_group episode group id
    * @param i_prob_group  group id
    * @param i_assessment_note assessment note
    * @param i_plan_note plan note
    
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/10
    **********************************************************************************************/
    FUNCTION set_epis_prob_group_note
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_epis_prob_grp_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_epis_prob_group   IN epis_prob_group.id_epis_prob_group%TYPE,
        i_assessment_note      IN CLOB,
        i_plan_note            IN CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * get_max_problem_group
    *
    * @param i_lang The language id
     * @param i_prof The professional, institution and software ids
    * @param i_epis The episode id
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return max. episode group number.
    *
    * @author : Lillian Lu
     * @since 2017/11/10
    **********************************************************************************************/
    FUNCTION get_max_problem_group
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_group OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * get_epis_problem
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_pat patient id
    * @param i_status
    * @param i_type
    * @param i_problem
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/23
    **********************************************************************************************/
    FUNCTION get_epis_problem
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_pat        IN pat_history_diagnosis.id_patient%TYPE,
        i_status     IN table_varchar,
        i_type       IN VARCHAR2,
        i_id_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        o_problem    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * validate_epis_prob_group ( check if no any problem in the specific group)
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_prob_group  group id
    * @param i_problem
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if has problems in the group, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/24
    **********************************************************************************************/
    FUNCTION validate_epis_prob_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_problem        IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_prob_group        IN epis_prob_group.prob_group%TYPE,
        o_prob_in_epis_prob OUT VARCHAR2,
        o_prob_in_gorup     OUT VARCHAR2,
        o_prob_in_prev_epis OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************************
    * cancel_epis_problem
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_pat  patient id
    * @param i_id_episode The episode id
    * @param i_id_problem problem id
    * @param i_type                   Type of problem
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes
    * @param i_prof_cat_type          Professional category flag
    * @param i_flg_cancel_pat_prob    cancel patient problem flah:
    *                                                'Y' if need to cancel patient problem
    * @param o_error                  Error message
    *
    * @return True if has problems in the group, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/27
    **********************************************************************************************/
    FUNCTION cancel_epis_problem
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat                 IN pat_problem.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_problem          IN NUMBER,
        i_type                IN VARCHAR2,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_prob.cancel_notes%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_flg_cancel_pat_prob IN VARCHAR2,
        o_type                OUT table_varchar,
        o_ids                 OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets actions available for Problem List View
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   o_list                       List of actions available
    * @param   o_error                    Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Lillian Lu
    * @since   14-12-2017
    */
    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_prob_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_flg_status IN VARCHAR2,
        o_prob_group OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group     IN epis_prob_group.id_epis_prob_group%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        o_assessement            OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        notes_cancel             IN CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_dup_icd_problem
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_exception EXCEPTION;
    g_error VARCHAR2(4000 CHAR);
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';
    g_package_name VARCHAR2(32);

END;
/
