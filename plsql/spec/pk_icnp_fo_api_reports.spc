/*-- Last Change Revision: $Rev: 2028731 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_icnp_fo_api_reports IS

    --------------------------------------------------------------------------------
    -- METHODS [GETS]
    --------------------------------------------------------------------------------

    /**
    * Get data on diagnoses and interventions, for the grid view.
    * Based on PK_ICNP's GET_DIAG_SUMMARY and GET_INTERV_SUMMARY.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_diag         diagnoses cursor
    * @param o_interv       interventions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/06/29
    */
    FUNCTION get_icnp_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_diag         OUT pk_types.cursor_type,
        o_interv       OUT pk_types.cursor_type,
        o_interv_presc OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns ICNP's diagnosis hist
    *
    * @param      i_lang    Preferred language ID for this professional
    * @param      i_prof    Object (professional ID, institution ID, software ID)
    * @param      i_diag    Diagnosis ID
    * @param      i_episode            Episode identifier
    * @param      o_diag    Diagnosis cursor
    * @param      o_r_diag  Most recent diagnosis
    * @param      o_error   Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Sérgio Santos (based on pk_icnp.get_diag_hist)
    * @version               2.5.1
    * @since                 2010/08/03
    *********************************************************************************************/
    FUNCTION get_diagnosis_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_diag    IN icnp_epis_diagnosis.id_icnp_epis_diag%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_diag    OUT pk_types.cursor_type,
        o_r_diag  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns ICNP's intervention history
    *
    * @param      i_lang                      Preferred language ID for this professional
    * @param      i_prof                      Object (professional ID, institution ID, software ID)
    * @param      i_patient                   Patient ID
    * @param      i_episode                   Episode ID
    * @param      i_interv                    Intervetion ID
    * @param      o_interv_curr               Intervention current state
    * @param      o_interv                    Intervention detail
    * @param      o_epis_doc_register         array with the detail info register
    * @param      o_epis_document_val         array with detail of documentation
    * @param      o_error                     Error
    *
    * @return                boolean type, "False" on error or "True" if success
    *
    * @author                Nuno Neves
    * @version               2.6.1
    * @since                 2011/03/23
    *********************************************************************************************/
    FUNCTION get_interv_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_episode           IN icnp_epis_intervention.id_episode%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_interv_curr       OUT pk_types.cursor_type,
        o_interv            OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the associated diagnosis of a list of interventions
    *
    * @param      i_lang               Preferred language ID for this professional
    * @param      i_epis_interv        Intervention id
    * @param      o_error              Error object
    *
    * @return               varchar2 with associated diagnosis
    *
    * @raises
    *
    * @author                Sérgio Santos
    * @version               2.5.1
    * @since                 2010/08/31
    *********************************************************************************************/
    FUNCTION get_interv_assoc_diag_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get intervention instructions description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_interv       intervention identifier
    *
    * @return               intervention instructions description
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/07/06
    */
    FUNCTION get_interv_instructions
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_interv IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) RETURN sys_message.desc_message%TYPE;

END pk_icnp_fo_api_reports;
/
