/*-- Last Change Revision: $Rev: 2028723 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp IS

    FUNCTION get_compo_dep_clin_serv
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE, --ALERT-20717
        i_diag         IN icnp_epis_diagnosis.id_composition%TYPE,
        i_dcs          IN icnp_compo_dcs.id_dep_clin_serv%TYPE,
        o_action_compo OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION desc_composition
    (
        i_lang        IN language.id_language%TYPE,
        i_composition IN icnp_composition.id_composition%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_compo
    (
        i_lang        IN language.id_language%TYPE,
        i_type        IN icnp_composition.flg_type%TYPE,
        i_nurse_tea   IN icnp_composition.flg_nurse_tea%TYPE DEFAULT NULL,
        i_folder      IN icnp_folder.id_folder%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        o_composition OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diag_viewer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diag_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN icnp_epis_diagnosis.id_episode%TYPE,
        i_diag      IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_interv    IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_status    IN icnp_epis_diagnosis.flg_status%TYPE,
        i_prof      IN profissional,
        o_diagnoses OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Interventions
    */
    FUNCTION get_interv_det
    (
        i_lang          IN language.id_language%TYPE,
        i_interv        IN table_number, --icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_prof          IN profissional,
        o_interventions OUT pk_types.cursor_type,
        --o_task_det      OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_interv_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN icnp_epis_intervention.id_episode%TYPE,
        i_diag          IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_status        IN icnp_epis_intervention.flg_status%TYPE,
        i_prof          IN profissional,
        dt_server       OUT VARCHAR2,
        o_interventions OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_most_recent_interv
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN icnp_epis_intervention.id_patient%TYPE,
        i_episode  IN icnp_epis_intervention.id_episode%TYPE,
        i_interv   IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_r_interv OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Nursing Teaching
    */

    /**********
    * Others *
    **********/
    FUNCTION get_folder
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_interv_list
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_interv  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_interv_summary_active
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_interv  OUT pk_types.cursor_type,
        o_proc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /** @headcom
    * Public Function. Actualizar o episódio de origem nos ensinos de enfermagem bem como as respectivas tabelas de relação.
    * Utilizada aquando a passagem de Urgência para Internamento será necessário actualizar o ID_EPISODE nos ensinos de enfermagem
                          com o novo episódio (INP) e o ID_EPISODE_ORIGIN ficará com o episódio de urgência (EDIS)
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_PROF              ID do profissional, software e instituição
    * @param      I_PROF_CAT_TYPE     Categoria do profissional
    * @param      I_EPISODE           ID do episódio original do ensino de enfermagem
    * @param      I_NEW_EPISODE       ID do novo episódio
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     ET
    * @version    0.1
    * @since      2007/04/10
    */
    --
    FUNCTION get_cipe_search
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_type      IN icnp_composition.flg_type%TYPE,
        i_nurse_tea IN icnp_composition.flg_nurse_tea%TYPE DEFAULT NULL,
        i_folder    IN icnp_folder.id_folder%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_search    IN VARCHAR2,
        o_info      OUT pk_types.cursor_type,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_interv_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_interv_interval
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_interval OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_interv_duration_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_duration OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculates an order rank used for sorting exams
    *
    * @param i_lang        Language id
    * @param i_prof        Professional
    * @param i_patient     Patient id
    * @param o_num_occur
    * @param o_desc_first
    * @param o_code_first
    * @param o_dt_first
    * @param o_error
    *
    * @return boolean
    *
    * @author Ana Matos
    * @version 2.4.3d
    * @since 2008/11/24
    */
    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculates an order rank used for sorting exams
    *
    * @param i_lang          Language id
    * @param i_prof          Professional
    * @param i_patient       Patient id
    * @param o_ordered_list
    * @param o_error
    *
    * @return boolean
    *
    * @author Ana Matos
    * @version 2.4.3d
    * @since 2008/11/24
    */
    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*s
      CIPE BUILDER
    */

    FUNCTION get_icnp_existing_term
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_folder OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_composition_by_term
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_term      IN table_number,
        i_flg_child IN VARCHAR2,
        o_folder    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_composition_by_term
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_term       IN table_number,
        i_flg_child  IN VARCHAR2,
        i_comp       IN icnp_composition.id_composition%TYPE,
        i_backoffice IN VARCHAR2 DEFAULT 'N',
        o_folder     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_interv_or_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_comp       IN icnp_composition_hist.id_composition_hist%TYPE,
        i_flag       VARCHAR2,
        i_interv_old IN table_number,
        o_folder     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_search_term
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_search    IN VARCHAR2,
        i_type      IN icnp_axis.flg_type%TYPE,
        o_info      OUT pk_types.cursor_type,
        o_error     OUT t_error_out,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION concatenate_list(i_cursor IN SYS_REFCURSOR) RETURN VARCHAR2;

    FUNCTION get_icnp_axis
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN icnp_axis.flg_type%TYPE,
        o_axis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_term
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_axis  IN icnp_axis.id_axis%TYPE,
        i_term  IN icnp_term.id_term%TYPE,
        o_term  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_diag_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_comp          IN icnp_composition.id_composition%TYPE,
        i_comp_hst      IN icnp_composition_hist.id_composition_hist%TYPE,
        o_date          OUT table_varchar,
        o_pro           OUT table_varchar,
        o_focus         OUT table_varchar,
        o_diag          OUT table_varchar,
        o_diagre        OUT table_varchar,
        o_interv        OUT table_varchar,
        o_status        OUT table_varchar,
        o_flg_cancel    OUT VARCHAR2,
        o_cancel_reason OUT table_varchar,
        o_cancel_r      OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_interv_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_comp          IN icnp_composition.id_composition%TYPE,
        i_comp_hst      IN icnp_composition_hist.id_composition_hist%TYPE,
        o_date          OUT table_varchar,
        o_pro           OUT table_varchar,
        o_action        OUT table_varchar,
        o_comp          OUT table_varchar,
        o_diagre        OUT table_varchar,
        o_app           OUT table_varchar,
        o_status        OUT table_varchar,
        o_flg_cancel    OUT VARCHAR2,
        o_cancel_reason OUT table_varchar,
        o_cancel_r      OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_comp_by_search
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_search    IN VARCHAR2,
        o_folder    OUT pk_types.cursor_type,
        o_error     OUT t_error_out,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION create_icnp_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_term    IN table_number,
        i_term_tx IN table_varchar,
        i_term_fs IN icnp_composition_term.id_term%TYPE,
        i_comp    IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_icnp_interv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_term          IN table_number,
        i_term_tx       IN table_varchar,
        i_term_fs       IN icnp_composition_term.id_term%TYPE,
        i_comp          IN table_number,
        i_comp_hst      IN table_number,
        i_apli          IN icnp_application_area.id_application_area%TYPE,
        i_flg_most_freq IN table_varchar,
        i_soft          IN table_number,
        i_inst          IN table_table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_diag_for_update
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_comp     IN icnp_composition.id_composition%TYPE,
        i_comp_hst IN icnp_composition_hist.id_composition_hist%TYPE,
        o_term     OUT pk_types.cursor_type,
        o_comp     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_interv_for_update
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_comp     IN icnp_composition.id_composition%TYPE,
        i_comp_hst IN icnp_composition_hist.id_composition_hist%TYPE,
        o_term     OUT pk_types.cursor_type,
        o_comp     OUT pk_types.cursor_type,
        o_area     OUT pk_types.cursor_type,
        o_inst     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_equal_terms
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_flag  IN VARCHAR2,
        i_term  IN table_number,
        i_comp  IN icnp_composition_hist.id_composition_hist%TYPE DEFAULT NULL,
        o_desc  OUT table_varchar,
        o_comp  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_soft_dept
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_term        IN icnp_term.id_term%TYPE,
        o_activ_servs OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_departments
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN software.id_software%TYPE,
        i_dept  IN dept.id_dept%TYPE,
        i_term  IN icnp_term.id_term%TYPE,
        o_deps  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN software.id_software%TYPE,
        i_depa  IN department.id_department%TYPE,
        i_term  IN icnp_term.id_term%TYPE,
        o_serv  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_icnp_focus_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_serv  IN table_table_number,
        i_soft  IN table_number,
        i_dept  IN table_number,
        i_focus IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_icnp_diag
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_comp     IN icnp_composition.id_composition%TYPE,
        i_reason   IN icnp_composition_hist.id_cancel_reason%TYPE,
        i_rsn_nts  IN icnp_composition_hist.reason_notes%TYPE,
        i_flg_warn IN VARCHAR2,
        o_list     OUT table_varchar,
        o_id_list  OUT table_number,
        o_flag     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_icnp_interv
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_diag    IN icnp_composition.id_composition%TYPE,
        i_interv  IN icnp_composition.id_composition%TYPE,
        i_reason  IN icnp_composition_hist.id_cancel_reason%TYPE,
        i_rsn_nts IN icnp_composition_hist.reason_notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_icnp_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_term    IN table_number,
        i_term_tx IN table_varchar,
        i_term_fs IN icnp_composition_term.id_term%TYPE,
        i_prv_cmp IN icnp_composition.id_composition%TYPE,
        i_prv_cht IN icnp_composition_hist.id_composition_hist%TYPE,
        i_comp    IN table_number,
        i_flg_cmp IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_icnp_interv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_term          IN table_number,
        i_term_tx       IN table_varchar,
        i_term_fs       IN icnp_composition_term.id_term%TYPE,
        i_comp          IN table_number,
        i_prv_cmp       IN icnp_composition.id_composition%TYPE,
        i_prv_cht       IN icnp_composition_hist.id_composition_hist%TYPE,
        i_flg_cmp       IN VARCHAR2,
        i_apli          IN icnp_application_area.id_application_area%TYPE,
        i_flg_most_freq IN table_varchar,
        i_soft          IN table_number,
        i_inst          IN table_table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_compo_desc_aux
    (
        i_lang language.id_language%TYPE,
        i_comp IN icnp_composition.id_composition%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_compo_desc
    (
        i_lang language.id_language%TYPE,
        i_comp IN icnp_composition.id_composition%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_compo_desc_by_date
    (
        i_lang language.id_language%TYPE,
        i_comp IN icnp_composition_hist.id_composition_hist%TYPE,
        i_date IN DATE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns a list of diagnoses according to the professional's category (physician/nurse)
    *
    * @param      i_lang    Language
    * @param      i_prof    Professional
    * @param      i_episode Episode
    * @param      o_diag    Cursor with the diagnoses
    * @param      o_error   Error message
    *
    * @return     True on success, false otherwise
    *
    * @author     Joao Martins
    * @version    2.6.0.1
    * @since      2010/03/17
    *********************************************************************************************/
    FUNCTION get_diagnoses
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     *   
     *  Returns the id of the profile of the logged professional.  
     *
     * @param i_lang                 Language ID
     * @param i_prof                 The ALERT professional calling this function
     * @param o_id_profile_template  ID of the corresponding PROFILE_TEMPLATE
     * @param o_error   
     *
     * @return                         true or false 
     *
     * @author                          RicardoNunoAlmeida
     * @version                         2.5.0.7.6.1
     * @since                           2010/02/10
    **********************************************************************************************/
    FUNCTION get_prof_profile_template
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_id_profile_template OUT prof_profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_version
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER;

    FUNCTION get_icnp_validation_flags
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_validation_flag
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_flg  IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        i_prof              IN profissional,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *  This function removes all information about ICNP registers (RESET).
    
    *
    * @param i_lang                   Language ID
    * @param i_prof                   The ALERT professional calling this function
    * @param i_patient                Table of id_patient to be clean.
    * @param i_episode                Table of id_episode to be clean.
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          28-APR-2011
    **********************************************************************************************/
    FUNCTION clear_icnp_reset
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get advanced input application areas
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      o_areas   List of application_areas
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_adv_input_areas
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_areas OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get advanced input application area parameters
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_area    Area code
    * @param      o_params  List of application_area parameters
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @raises
    *
    * @author                Pedro Lopes
    * @version               1
    * @since                 2009/04/16
    * @dependents            PK_TRANSLATION.GET_TRANSLATION       <TEAM_TO_ADVISE>
    *                        PK_ALERT_EXCEPTIONS.PROCESS_ERROR    <TEAM_TO_ADVISE>
    *                        PK_MESSAGE.GET_MESSAGE               <TEAM_TO_ADVISE>
    *                        PK_TYPES.OPEN_MY_CURSOR              <TEAM_TO_ADVISE>
    *********************************************************************************************/
    FUNCTION get_adv_input_parameters
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_area   IN icnp_application_area.area%TYPE,
        o_params OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_icnp_instructions_msi
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN table_number,
        i_inst  IN table_table_varchar,
        i_comp  IN icnp_composition.id_composition%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nurse_sections
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_summary_page     IN summary_page.id_summary_page%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        o_label_nurse_eval    OUT VARCHAR2,
        o_doc_area_nurse_desc OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_icnp_tooltip
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_task  IN NUMBER,
        i_flg_type IN VARCHAR2,
        i_screen   IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_icnp_exec_tooltip
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task      IN NUMBER,
        i_id_diag      IN NUMBER,
        i_id_interv    IN NUMBER,
        i_id_plan      IN NUMBER,
        i_id_diag_hist IN NUMBER,
        i_flg_type     IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_icnp_by_status
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_icnp_diag OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    --- ################################################################## ---
    --

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_found         BOOLEAN;
    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char  VARCHAR2(50);
    g_error         VARCHAR2(2000);
    g_error2        VARCHAR2(2000);
    g_exception EXCEPTION;

    TYPE t_rec_aux_section IS RECORD(
        translated_code pk_translation.t_desc_translation,
        flg_scope_type  doc_area_inst_soft.flg_scope_type%TYPE,
        id_doc_area     summary_page_section.id_doc_area%TYPE);

END pk_icnp;
/
