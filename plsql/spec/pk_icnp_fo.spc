CREATE OR REPLACE PACKAGE pk_icnp_fo IS

    --------------------------------------------------------------------------------
    -- PUBLIC METHODS
    --------------------------------------------------------------------------------

    /**
    * Checks if diagnoses for association are available.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_interv       interventions identifiers list
    * @param o_flg_show     shows warning message: Y - yes, N - No
    * @param o_msg          message text
    * @param o_msg_title    message title
    * @param o_button       buttons to show: N-No, R-Read, C-Confirmed
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/18
    */
    PROCEDURE check_assoc_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_interv    IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2
    );

    /**
    * Checks selected ICNP diagnoses and interventions for conflicts. We can't
    * have request diagnosis that are still active or suspended and interventions
    * that are still ongoing, requested or suspended for the patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_diag         selected diagnosis list
    * @param i_interv       selected interventions list
    * @param o_warn         conflict warning
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/02
    */
    PROCEDURE check_epis_conflict
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_diag       IN table_number,
        i_interv     IN table_number,
        i_flg_sug    IN VARCHAR2,
        o_warn       OUT table_varchar,
        o_desc_instr OUT pk_types.cursor_type
        
    );

    /**
    * Checks selected ICNP care plans for conflicts.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_cplan        icnp care plans identifiers list
    * @param o_exp_res      conflicted expected results cursor
    * @param o_interv       conflicted interventions cursor
    * @param o_sel_compo    unconflicted compositions list
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/13
    */
    PROCEDURE check_conflict
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_cplan     IN table_number,
        o_exp_res   OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type,
        o_sel_compo OUT table_number
    );

    PROCEDURE check_therapeutic_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN table_number, --icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg_result          OUT VARCHAR2,
        o_title               OUT VARCHAR2,
        o_button              OUT VARCHAR2
    );

    /**
    * Get list of diagnoses for reevaluation.
    *
    * @param i_lang         language identifier
    * @param i_prof         Professional identifier
    * @param i_patient      Patient identifier
    * @param i_diag         current diagnosis identifier
    * @param o_diags        diagnoses cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/06
    */
    PROCEDURE get_reeval_diagnoses
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_diag      IN icnp_epis_diagnosis.id_composition%TYPE,
        i_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        o_diags     OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    );

    /**
    * Create an ICNP intervention: given a set of diagnosis,
    * interventions and it's instructions, set them to the specified
    * patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_diag         diagnosis identifiers list
    * @param i_exp_res      expected results identifiers list
    * @param i_notes        diagnosis notes list
    * @param i_interv       intervention identifiers and instructions list
    * @param i_cur_diag     current diagnosis identifier
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param i_moment_assoc Moment of creation of the association between intervention and diagnosis 'C' creation, 'A' association
    * @param o_interv_id    created icnp_epis_intervention ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    PROCEDURE create_icnp_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_diag           IN table_number,
        i_exp_res        IN table_number,
        i_notes          IN table_varchar,
        i_interv         IN table_table_varchar,
        i_cur_diag       IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_moment_assoc   IN icnp_epis_diag_interv.flg_moment_assoc%TYPE DEFAULT 'C',
        i_flg_type_assoc IN icnp_epis_diag_interv.flg_type_assoc%TYPE DEFAULT 'D',
        o_interv_id      OUT table_number
    );

    /********************************************************************************************
    * Creates or updates ICNP care plans (Configurations Area)
    *
    * @param i_lang            Preferred language ID for this professional
    * @param i_prof            Object (professional ID, institution ID, software ID)
    * @param i_cplan           Care plan ID (null value creates a cplan)
    * @param i_name            Care plan name
    * @param i_notes           Care plan notes
    * @param i_diags           Diagnosis
    * @param i_results         Diagnosis expected results
    * @param i_intervs         Interventions (intervention and instructions) Interventions (intervention and instructions) [[(1)ID_COMPOSITION, (2)ID_COMPOSITION_PARENT, (3)TAKE_TYPE, (4)NUM_TAKE, (5)INTERVAL, (6)INTERVAL_UNIT, (7)DURATION, (8)DURATION_UNIT],...]
    * @param i_dep_clin_serv   associated specialties list
    * @param i_soft            associated softwares list
    * @param i_sysdate_tstz    Current timestamp that should be used across all the 
    *                          functions invoked from this one.
    *
    * @return                  boolean type, "False" on error or "True" if success 
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/12
    *                         
    *********************************************************************************************/
    PROCEDURE create_or_update_icnp_cplan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_cplan         IN icnp_cplan_stand.id_cplan_stand%TYPE,
        i_name          IN VARCHAR2,
        i_notes         IN VARCHAR2,
        i_diags         IN table_number,
        i_results       IN table_number,
        i_intervs       IN table_table_varchar,
        i_dep_clin_serv IN table_number,
        i_soft          IN table_number,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
    * Get list of available actions, from a given state. When specifying more than one state,
    * it groups the actions, according to their availability. This enables support
    * for "bulk" state changes.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_subject      action subject
    * @param i_from_state   list of selected states
    * @param o_actions      actions cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    PROCEDURE get_actions_permissions
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_subject                IN action.subject%TYPE,
        i_from_state             IN table_varchar,
        id_icnp_epis_interv_diag IN table_number,
        o_actions                OUT pk_types.cursor_type
    );

    /********************************************************************************************
    *  Obter lista de opções para requisição
    *
    * @param      i_lang       Preferred language ID for this professional
    * @param      i_prof       Object (professional ID, institution ID, software ID)
    * @param      o_list       Clinical services
    *
    * @return                  boolean type, "False" on error or "True" if success 
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/17
    *********************************************************************************************/
    PROCEDURE get_create_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_list OUT pk_types.cursor_type
    );

    /**
    * Get ICNP create button available actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/05
    */
    PROCEDURE get_create_list_fo
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Returns diagnosis summary
    *
    * @param i_lang               Language identifier
    * @param i_prof               Logged professional structure
    * @param i_patient            Patient identifier
    * @param o_diag               Diagnoses cursor
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/02
    *********************************************************************************************/
    PROCEDURE get_diag_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_diag    OUT pk_types.cursor_type
    );

    /**
    * Get diagnosis conclusion warning.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_action       chosen action
    * @param i_diag         selected diagnosis list
    * @param o_warn         warning
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/09/16
    */
    PROCEDURE get_diag_warn
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.internal_name%TYPE,
        i_diag   IN table_number,
        o_warn   OUT table_varchar
    );

    /********************************************************************************************
    * Returns ICNP's diagnosis hist
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_diag    Diagnosis ID
    * @param      i_episode            Episode identifier
    * @param      o_diag    Diagnosis cursor
    * @param      o_r_diag  Most recent diagnosis
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Sérgio Santos (based on pk_icnp.get_diag_hist)
    * @version               2.5.1
    * @since                 2010/08/03
    *********************************************************************************************/
    PROCEDURE get_diagnosis_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_diag    IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_r_diag  OUT pk_types.cursor_type
    );

    /**
    * :TODO:
    */
    PROCEDURE load_standard_cplan_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sel_compo IN table_number,
        o_diags     OUT pk_types.cursor_type,
        o_interv    OUT pk_types.cursor_type
    );

    /**
     * :TODO:
    */
    PROCEDURE load_standard_cplan_info_bo
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_cplan_stand IN icnp_cplan_stand_compo.id_cplan_stand%TYPE,
        o_diags       OUT pk_types.cursor_type,
        o_interv      OUT pk_types.cursor_type,
        o_name        OUT VARCHAR2,
        o_notes       OUT VARCHAR2,
        o_dcs         OUT pk_types.cursor_type,
        o_soft        OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Get ICNP care plan intervention instructions (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_instr     Interventions instructions
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @raises                
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/12
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_instr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_fields     OUT pk_types.cursor_type,
        o_fields_det OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Get ICNP care plan (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_plan      Care plan ID
    * @param      o_name      Care plan name
    * @param      o_notes     Care plan notes
    * @param      o_diags     Diagnosis
    * @param      o_results   Diagnosis expected results
    * @param      o_intervs   Interventions (intervention and instructions) 
    * @param      o_dcs       associated specialties list
    * @param      o_soft      associated softwares list
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_view
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_plan   IN icnp_cplan_stand.id_cplan_stand%TYPE,
        o_name   OUT VARCHAR2,
        o_status OUT VARCHAR2,
        o_notes  OUT VARCHAR2,
        o_diags  OUT pk_types.cursor_type,
        o_interv OUT pk_types.cursor_type,
        o_dcs    OUT pk_types.cursor_type,
        o_soft   OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Get ICNP care plan expected results (Configurations Area)
    * The results are diagnosis with the same focus than the i_diag provided
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_diag      ICNP Diagnosis
    * @param      o_results   Diagnosis expected results
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @raises                
    *
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_results
    (
        i_lang    IN language.id_language%TYPE,
        i_diag    IN icnp_composition.id_composition%TYPE,
        i_prof    IN profissional,
        o_results OUT pk_types.cursor_type
    );

    /**
    * Get time icnp terms that belongs to the axis "action" that already have some composition associated
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      Patient identifier
    * @param o_terms        The icnp terms that belongs to the axis "action"
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sérgio Santos
    * @version              2.5.1
    * @since                2010/07/22
    */
    PROCEDURE get_action_terms
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type
    );

    /**
    * Gets a list of interventions that belongs to a specific icnp term in the axis "action"
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_term         icnp term identifier
    * @param i_patient      Patient identifier (optional)
    * @param o_intervs      list of interventions
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sérgio Santos
    * @version               2.5.1
    * @since                2010/07/22
    */
    PROCEDURE get_interv_by_action_term
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_term IN icnp_term.id_term%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_intervs OUT pk_types.cursor_type
    );

    /**
    * Get data on diagnoses and interventions, for the grid view.
    * Based on PK_ICNP's GET_DIAG_SUMMARY and GET_INTERV_SUMMARY.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_diag         diagnoses cursor
    * @param o_interv       interventions cursor
    * @param o_interv_presc List of interventions that were suggested by a 
    *                       therapeutic attitude.
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/06/29
    */
    PROCEDURE get_icnp_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_diag         OUT pk_types.cursor_type,
        o_interv       OUT pk_types.cursor_type,
        o_interv_presc OUT pk_types.cursor_type
    );

    /**
    * Get available ICNP care plans list.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_cplan        icnp care plans cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/07
    */
    PROCEDURE get_cplan_fo
    (
        i_prof  IN profissional,
        o_cplan OUT pk_types.cursor_type
    );

    /*
    * Returns the tasks and views for the timeline view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     i_episode  Episode id
    * @param     i_status   status    
    * @param     o_tasks    Tasks list
    * @param     o_view     Views list
    
    * @return    true or false on success or error
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/08/03
    */
    PROCEDURE get_icnp_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN interv_icnp_ea.id_patient%TYPE,
        i_episode IN icnp_epis_diagnosis.id_episode%TYPE,
        i_status  IN icnp_epis_diagnosis.flg_status%TYPE,
        o_tasks   OUT pk_types.cursor_type,
        o_view    OUT pk_types.cursor_type
    );

    /**
    * Get data for the nurse interventon suggested with prescription.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_task         task cursor
    * @param o_interv       interventions cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.5.1
    * @since                21-01-2011
    */
    PROCEDURE get_icnp_sug_interv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_task    OUT pk_types.cursor_type,
        o_interv  OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_epis_interv        List of interventions
    * @param      o_diag               Diagnosis list description
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/06
    *********************************************************************************************/
    PROCEDURE get_interv_assoc_diag_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_interv IN table_number,
        o_diag        OUT VARCHAR2
    );

    /**
     * :TODO:
    */
    PROCEDURE get_interv_edit
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_detail OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Returns ICNP's intervention history
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_patient                   Patient ID
    * @param      i_interv                    Intervetion ID
    * @param      o_interv_curr               Intervention current state
    * @param      o_interv                    Intervention detail
    * @param      o_epis_doc_register         array with the detail info register
    * @param      o_epis_document_val         array with detail of documentation
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Nuno Neves
    * @version               2.6.1
    * @since                 2011/03/23
    *********************************************************************************************/
    PROCEDURE get_interv_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_reports           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_interv_curr       OUT pk_types.cursor_type,
        o_interv            OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type
    );

    /**
     * Gets the available PRN options.
     * 
     * @param i_lang The professional preferred language.
     * @param o_list The list of the available PRN options.
     * 
     * @return TRUE if sucess, FALSE otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 30/May/2011
    */
    PROCEDURE get_prn_list
    (
        i_lang IN language.id_language%TYPE,
        o_list OUT pk_types.cursor_type
    );

    /**
    * Get time flag domain, for the specified softwares.
    * Based on PK_LIST.GET_EXAM_TIME.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soft         softwares list
    * @param o_time         domains cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/07
    */
    PROCEDURE get_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_soft IN table_number,
        o_time OUT pk_types.cursor_type
    );

    /**
     * Returns the type description of a given composition identifier.
     * 
     * @param i_lang The professional preferred language.
     * @param i_composition Composition identifier.
     * 
     * @return The description of the type of the given composition.
     * 
     * @author Luis Oliveira
     * @version 2.6.1
     * @since 14-Jun-2011
    */
    FUNCTION get_compo_type_desc
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_composition IN sys_domain.val%TYPE
    ) RETURN sys_domain.desc_val%TYPE;

    /**
    * Associate diagnosis.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_diag         diagnoses identifiers list
    * @param i_interv       interventions identifiers list
    * @param o_edi_id       created icnp_epis_diag_interv ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/09
    */
    PROCEDURE set_assoc_diag
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_diag   IN table_number,
        i_interv IN table_number
    );

    /**
    * Get list of diagnoses for association.
    *
    * @param i_lang         language identifier
    * @param i_patient      patient identifier
    * @param i_interv       interventions identifiers list
    * @param o_diag         diagnoses cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/09
    */
    PROCEDURE get_assoc_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_interv  IN table_number,
        o_diag    OUT pk_types.cursor_type
    );

    /**
    * Associate intervention.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_diag         diagnosis identifier
    * @param i_interv       intervention identifiers and instructions list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param o_interv_id    created icnp_epis_intervention ids
    * @param o_edi_id       created icnp_epis_diag_interv ids
    * @param o_exec_id      created icnp_interv_plan ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/20
    */
    PROCEDURE set_assoc_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_diag         IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_interv       IN table_table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH TIME ZONE,
        o_interv_id    OUT table_number
    );

    /********************************************************************************************
    * Get ICNP care plan list (Configurations Area)
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      o_cplan     Cursor List of available Nursing Care Plans
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/05
    *                         
    *********************************************************************************************/
    PROCEDURE get_icnp_cplan_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_cplan OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Changes the status of a ICNP care plan
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    *
    * @return                 boolean type, "False" on error or "True" if success 
    * 
    * @author                  Sérgio Santos
    * @version                 2.5.1 
    * @since                   2010/05/06
    *                         
    *********************************************************************************************/
    PROCEDURE set_icnp_cplan_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_cplan   IN icnp_cplan_stand.id_cplan_stand%TYPE,
        i_flg_status IN icnp_cplan_stand.flg_status%TYPE
    );

    /********************************************************************************************
    * Returns all composition terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang      Preferred language ID for this professional
    * @param      i_prof      Object (professional ID, institution ID, software ID)
    * @param      i_term      Focus term ID
    * @param      i_flg_child flag (Y/N to calculate has child nodes)
    * @param      o_folder    Icnp's focuses list
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @author                Sérgio Santos (added old terms support)
    * @version               1
    * @since                 2009/02/16
    *********************************************************************************************/
    PROCEDURE get_icnp_composition_by_term
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_term      IN table_number,
        i_flg_child IN VARCHAR2,
        i_patient   IN patient.id_patient%TYPE,
        o_folder    OUT pk_types.cursor_type
    );

    /********************************************************************************************
    * Returns all terms from focus axis that are already available throught diagnosis.
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_patient Patient identifier (optional)
    * @param      o_folder  Icnp's focuses list
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @author                Sérgio Santos (added old terms support)
    * @version               1
    * @since                 2009/02/16
    *********************************************************************************************/
    PROCEDURE get_icnp_existing_term
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_folder  OUT pk_types.cursor_type
    );

    /*
    * Returns the tasks and views for the timeline documentation view
    *
    * @param     i_lang     Language id
    * @param     i_prof     Professional
    * @param     i_patient  Patient id
    * @param     i_episode  Episode id
    * @param     i_status   status    
    * @param     o_tasks    Tasks list
    * @param     o_view     Views list
    
    * @return    true or false on success or error
    *
    * @author    Paulo Teixeira
    * @version   2.5.1
    * @since     2010/08/03
    */
    PROCEDURE get_icnp_doc_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN interv_icnp_ea.id_patient%TYPE,
        i_episode IN icnp_epis_diagnosis.id_episode%TYPE,
        i_status  IN icnp_epis_diagnosis.flg_status%TYPE,
        o_tasks   OUT pk_types.cursor_type,
        o_view    OUT pk_types.cursor_type
    );

    /**
    * Get list of available softwares.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_soft         softwares cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    PROCEDURE get_software
    (
        i_prof IN profissional,
        o_soft OUT pk_types.cursor_type
    );

    /**
    * Get list of available departments,
    * associated with the specified softwares.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_soft         softwares list
    * @param i_search       user input for name search
    * @param o_dept         departments cursor
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    PROCEDURE get_dept
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_soft   IN table_number,
        i_search IN pk_translation.t_desc_translation,
        o_dept   OUT pk_types.cursor_type
    );

    /**
    * Creates interventions for "this episode", given the interventions
    * for the "next episode", set on a previous visit.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_past_episode past episode identifier
    * @param i_next_episode next episode identifier (the one being registered)
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/19
    */
    PROCEDURE create_interv_next_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_past_episode IN episode.id_episode%TYPE,
        i_next_episode IN episode.id_episode%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    );

    --
    --
    -- :TODO: remove
    -- Used only in selects
    --
    --

    /*
    * Build status string. Internal use only.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_type           status string type
    * @param i_status         status flag
    * @param i_timestamp      status date
    * @param i_shortcut       shortcut identifier
    * @param i_flg_prn        Flag that indicates if the intervention should only be executed as 
    *                         the situation demands.
    * 
    * @return                 status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.5.1
    * @since                  2010/07/30
    */
    FUNCTION get_status_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type        IN VARCHAR2,
        i_status      IN interv_icnp_ea.flg_status%TYPE,
        i_timestamp1  IN interv_icnp_ea.dt_next%TYPE := NULL,
        i_timestamp2  IN interv_icnp_ea.dt_next%TYPE := NULL,
        i_exec_number IN icnp_interv_plan.exec_number%TYPE := NULL,
        i_shortcut    IN sys_shortcut.id_sys_shortcut%TYPE := NULL,
        i_flg_prn     IN interv_icnp_ea.flg_prn%TYPE
    ) RETURN sys_domain.desc_val%TYPE;

    FUNCTION get_interv_instructions
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc;
    FUNCTION get_interv_hist_instructions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_interv_hist IN icnp_epis_intervention_hist.id_icnp_epis_interv_hist%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc;
    FUNCTION get_interv_assoc_diag(i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE) RETURN table_number;
    FUNCTION get_interv_instructions_bo
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_interv   IN icnp_cplan_stand_compo.id_cplan_stand_compo%TYPE,
        i_dt_begin IN interv_icnp_ea.dt_begin%TYPE := NULL
    ) RETURN pk_icnp_type.t_instruction_desc;
    FUNCTION check_visibility
    (
        i_prof        IN profissional,
        i_view_status IN VARCHAR2,
        i_rec_status  IN interv_icnp_ea.flg_status%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_rec_episode IN episode.id_episode%TYPE,
        i_dt_exec     IN interv_icnp_ea.dt_take_ea%TYPE,
        i_days_behind IN NUMBER
    ) RETURN PLS_INTEGER;
    FUNCTION check_permissions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subject IN action.subject%TYPE,
        i_status  IN action.from_state%TYPE,
        i_check   IN action.internal_name%TYPE
    ) RETURN VARCHAR2;
    FUNCTION check_exec_permission(i_interv_plan IN icnp_interv_plan.id_icnp_interv_plan%TYPE) RETURN VARCHAR2;
    FUNCTION get_diag_interventions_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_icnp_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_show_instr     IN VARCHAR2,
        i_sep            IN VARCHAR2,
        i_end            IN VARCHAR2,
        i_dt_limit       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_report     IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;
    FUNCTION get_interv_hist_value
    (
        i_patient              IN icnp_epis_intervention.id_patient%TYPE,
        i_dt_vital_sign_read   IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_id_vital_sign        IN vital_sign_read.id_vital_sign%TYPE,
        i_id_vital_sign_parent IN vital_sign_relation.id_vital_sign_parent%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_interv_prior_status
    (
        i_id_icnp_epis_interv icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_id_interv_hist      icnp_epis_intervention_hist.id_icnp_epis_interv_hist%TYPE
    ) RETURN icnp_epis_intervention_hist.flg_status%TYPE;
    FUNCTION get_interv_assoc_diag_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN icnp_epis_intervention.flg_type%TYPE,
        i_flg_time          IN icnp_epis_intervention.flg_time%TYPE,
        i_dt_begin_tstz     IN icnp_epis_intervention.dt_begin_tstz%TYPE,
        i_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE,
        i_mask              IN pk_icnp_type.t_instruction_mask DEFAULT pk_icnp_constant.g_inst_format_mask_default
    ) RETURN pk_icnp_type.t_instruction_desc;

    /**
    * Returns the flg_status of the prior id_icnp_epis_diagnosis_hist provided.
    *
    * @param i_id_icnp_epis_diagnosis   icnp diagnosis id
    * @param id_interv_hist             Base interv_hist
    *
    * @return               flg_status of icnp diagnosis previous that was provided
    *
    * @author               Nuno Neves
    * @version              2.5.1.7
    * @since                2011/09/09
    */
    FUNCTION get_diag_prior_status
    (
        i_id_icnp_epis_diag icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_id_interv_hist    icnp_epis_diagnosis_hist.id_icnp_epis_diag_hist%TYPE
    ) RETURN icnp_epis_diagnosis_hist.flg_status%TYPE;

    FUNCTION get_perform_desc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_flg_time             IN icnp_epis_intervention.flg_time%TYPE,
        i_id_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc;
    -- Gets the text with the frequency of the executions
    FUNCTION get_frequency_desc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_flg_type             IN icnp_epis_intervention.flg_type%TYPE,
        i_id_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc;

    -- Gets the text that describes when the task should be performed
    FUNCTION get_start_date_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN icnp_epis_intervention.dt_begin_tstz%TYPE
    ) RETURN pk_icnp_type.t_instruction_desc;

    /**
     * Load needed info about intervention and it's instructions
     * This method gets all the data needed to update de recurrence. interventions and it's instructions
     * 
     * @param i_lang                      The professional preferred language.
     * @param i_prof                      The professional context [id user, id institution, id software].
     * @param i_id_icnp_epis_interv       The icnp_epis_intervention identifier whose details we want to retrieve. 
     *
     * @param o_interv All the details of the selected interventions needed to populate
     *                the UX form.
     * 
     * @author Nuno Neves
     * @version 2.5.1.8.2
     * @since 10/10/2011
    */
    PROCEDURE load_icnp_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv              OUT pk_types.cursor_type
    );

    /**
    * Update an ICNP intervention: given a set of interventions and it's instructions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifiers and instructions list
    * @param i_sysdate_tstz Current timestamp that should be used across all the 
    *                       functions invoked from this one.
    * @param i_origin       parameter to identify if the plan is being executed (E)
    *                       or modified/created (M) 
    * @param o_interv_id    created icnp_epis_intervention ids
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Nuno Neves
    * @version              2.5.1.8.2
    * @since                2011/10/10
    */
    PROCEDURE update_icnp_interv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv       IN table_varchar,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_origin       IN VARCHAR2,
        o_interv_id    OUT table_number
    );

    PROCEDURE updt_icnp_plan
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN table_varchar
    );

    PROCEDURE updt_start_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN table_varchar
    );

    /********************************************************************************************
    * Returns ICNP's left_state of interv
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_flg_status                FLG_STAUS  status of icnp_epis_interv
    * @param      i_prev_flg_status           PREV_FLG_STAUS previous status of icnp_epis_interv
    *
    * @return                varchar left_state of interv
    *
    * @author                Nuno Neves
    * @version               2.5.1
    * @since                 2012/12/20
    *********************************************************************************************/
    FUNCTION get_left_state_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status      IN icnp_epis_intervention.flg_status%TYPE,
        i_prev_flg_status IN icnp_epis_intervention.flg_status%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns ICNP's left_state of exec
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_flg_status                FLG_STAUS icnp_interv_plan
    * @param      i_id_icnp_interv_plan       id_icnp_interv_plan
    *
    * @return                varchar left_state of exec
    *
    * @author                Nuno Neves
    * @version               2.5.1
    * @since                 2012/12/20
    *********************************************************************************************/
    FUNCTION get_left_state_exec
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status          IN icnp_epis_intervention.flg_status%TYPE,
        i_id_icnp_interv_plan IN icnp_interv_plan.id_icnp_interv_plan%TYPE
        
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_prof               Professional structure
    * @param      i_epis_interv        Intervention id
    * @param      i_dt_assoc           Date of association 
    * @param      i_momment_assoc      Moment of association
    *
    * @return               varchar2 with associated diagnosis
    *
    * @raises
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/02/27
    *********************************************************************************************/
    FUNCTION get_interv_rel_by_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_interv  IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_dt_assoc     IN icnp_epis_dg_int_hist.dt_hist%TYPE,
        i_moment_assoc IN icnp_epis_dg_int_hist.flg_moment_assoc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get timestamp truncated to minutes (seconds part will be zero)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_timestamp            timestamp to truncate
    *
    * @return      tsltz                  timestamp truncated to minutes
    *
    * @author                             Nuno Neves
    * @since                              27-02-2012
    ********************************************************************************************/
    FUNCTION trunc_timestamp_to_minutes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * Returns the list of interventions descriptions (optionally intructions) associated to a diagnosis
    *
    * @param      i_lang                    Preferred language ID for this professional
    * @param      i_prof                    Object (professional ID, institution ID, software ID)
    * @param      i_icnp_epis_diag          Diagnosis ID
    * @param      i_show_instr              Show intervention instructions (Y - yes, N - No)
    * @param      i_sep                     Word separator character
    * @param      i_end                     Word end character
    * @param      i_dt_limit                Maximum date of the intervention (Used to get differences)
    * @param      i_moment_assoc            Moment of association
    * @param      i_type_assoc              Type of association
    *
    * @return             String with interventions description (optionally intructions)
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/03/12
    *********************************************************************************************/
    FUNCTION get_diag_intervs_hist_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_icnp_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_show_instr     IN VARCHAR2,
        i_sep            IN VARCHAR2,
        i_end            IN VARCHAR2,
        i_dt_limit       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_moment_assoc   IN table_varchar,
        i_type_assoc     IN icnp_epis_diag_interv.flg_type_assoc%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get all information related to nursing interventions (relationships)
    * 
    * @param i_lang                              language identifier
    * @param i_prof                              logged professional structure
    * @param i_id_icnp_epis_inter_array          array with interventions ids
    * @param o_interv                            Interventions cursor                                               
    * @param o_diag                              Diagnoses cursor
    * @param o_task                              MCDT's cursor
    *              
    *
    * @author               Nuno Neves
    * @version               2.6.1
    * @since                2012/03/05
    */
    PROCEDURE get_icnp_rel_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_icnp_epis_inter_array IN table_number,
        o_interv                   OUT pk_types.cursor_type,
        o_diag                     OUT pk_types.cursor_type,
        o_task                     OUT pk_types.cursor_type
    );

    /**
    * Define the status of the relationship with nursing intervention
    * 
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_rel_array    array with information with actions for nursing interventions
    *              
    *
    * @author               Nuno Neves
    * @version               2.6.1
    * @since                2012/03/05
    */
    PROCEDURE set_status_rel_icnp
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_rel_array IN table_table_varchar
    );

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_epis_interv        Intervention id
    * @param      i_status_rel         array with status info
    * @param      i_id_icnp_epis_diag_interv     icnp_epis_diag_interv id    
    *
    * @return               varchar2 with associated diagnosis
    *
    * @raises
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/03/12
    *********************************************************************************************/
    FUNCTION get_interv_rel_by_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_epis_interv              IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_status_rel               IN table_varchar,
        i_id_icnp_epis_diag_interv IN icnp_epis_diag_interv.id_icnp_epis_diag_interv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the list of interventions descriptions (optionally intructions) associated to a diagnosis
    *
    * @param      i_lang                    Preferred language ID for this professional
    * @param      i_prof                    Object (professional ID, institution ID, software ID)
    * @param      i_icnp_epis_diag          Diagnosis ID
    * @param      i_show_instr              Show intervention instructions (Y - yes, N - No)
    * @param      i_sep                     Word separator character
    * @param      i_end                     Word end character
    * @param      i_dt_limit                Maximum date of the intervention (Used to get differences)
    *
    * @return             String with interventions description (optionally intructions)
    *
    * @author                Nuno Neves
    * @version               
    * @since                 2012/03/12
    *********************************************************************************************/
    FUNCTION get_diag_intervs_rel_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_icnp_epis_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_show_instr     IN VARCHAR2,
        i_sep            IN VARCHAR2,
        i_end            IN VARCHAR2,
        i_dt_limit       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_moment_assoc   IN table_varchar
    ) RETURN VARCHAR2;

    FUNCTION reeval_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_diag_ids       IN table_number,
        i_composition_id IN icnp_epis_diagnosis.id_composition%TYPE,
        i_interv_check   IN table_number,
        i_new_diag       IN table_number, ---- new id_diag
        i_new_interv     IN table_number,
        i_new_interv_ovr IN table_number,
        i_flg_sug        IN VARCHAR2,
        i_exp_res        IN table_number,
        i_notes          IN table_varchar,
        i_interv         IN table_table_varchar,
        o_interv_id      OUT table_number,
        o_warn           OUT table_varchar,
        o_desc_instr     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_interv_pred_by_diag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diag IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE
    ) RETURN table_varchar;

    PROCEDURE get_icnp_actions_sp
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        id_icnp_epis_interv_diag IN NUMBER,
        o_actions                OUT pk_types.cursor_type
    );

    FUNCTION get_actions_perm_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_flg_time   IN icnp_epis_intervention.flg_time%TYPE
    ) RETURN t_coll_action_cipe;

    FUNCTION get_icnp_interv_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_icnp_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    g_crit_type_a CONSTANT VARCHAR2(1) := 'A'; --All (executions and requests)  
    g_crit_type_e CONSTANT VARCHAR2(1) := 'E'; -- Executions 

    g_icnp_care_plan_e CONSTANT VARCHAR2(1) := 'E'; --Episode
    g_icnp_care_plan_v CONSTANT VARCHAR2(1) := 'V'; --Visit
    g_icnp_care_plan_p CONSTANT VARCHAR2(1) := 'P'; --Patient

END pk_icnp_fo;
/
