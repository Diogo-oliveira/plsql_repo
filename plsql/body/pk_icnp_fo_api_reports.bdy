/*-- Last Change Revision: $Rev: 2027225 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_fo_api_reports IS

    --------------------------------------------------------------------------------
    -- GLOBAL VARIABLES
    --------------------------------------------------------------------------------

    -- Identifes the owner in the log mechanism
    g_package_owner pk_icnp_type.t_package_owner;
    -- Identifes the package in the log mechanism
    g_package_name pk_icnp_type.t_package_name;
    -- Text that briefly describes the current operation
    g_current_operation pk_icnp_type.t_current_operation;

    --------------------------------------------------------------------------------
    -- PRIVATE METHODS [DEBUG AND ERROR HANDLING]
    --------------------------------------------------------------------------------

    /*
     * Wrapper of the method from the alertlog mechanism that creates a debug log 
     * message.
     *
     * @param i_text Text to log.
     * @param i_func_name Function / procedure name.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 28/Jul/2011
    */
    PROCEDURE log_debug
    (
        i_text      VARCHAR2,
        i_func_name VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_debug(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
    END log_debug;

    /**
     * Wrapper that performs error handling creating the log for the error.
     * 
     * @param i_lang The professional preferred language.
     * @param i_func_name Function / procedure name.
     * @param o_error An object with the details of the error.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 28/Jul/2011
    */
    PROCEDURE process_error
    (
        i_lang      IN language.id_language%TYPE,
        i_func_name IN pk_icnp_type.t_function_name,
        o_error     OUT t_error_out
    ) IS
    BEGIN
        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => SQLCODE,
                                          i_sqlerrm  => SQLERRM,
                                          i_message  => g_current_operation,
                                          i_owner    => g_package_owner,
                                          i_package  => g_package_name,
                                          i_function => i_func_name,
                                          o_error    => o_error);
        pk_alert_exceptions.reset_error_state;
    END;

    --------------------------------------------------------------------------------
    -- PRIVATE METHODS [INIT]
    --------------------------------------------------------------------------------

    /**
     * Executes all the instructions needed to correctly initialize the package.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 03/Jun/2011
    */
    PROCEDURE initialize IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'initialize';
    
    BEGIN
        -- Initializes the log mechanism
        g_current_operation := 'INIT LOG MECHANISM';
        g_package_owner     := 'ALERT';
        g_package_name      := pk_alertlog.who_am_i;
        pk_alertlog.log_init(g_package_name);
    
        -- Log message
        log_debug(c_func_name || '()', c_func_name);
    END;

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
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_ICNP_GRID';
    
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_icnp_grid function';
        pk_icnp_fo.get_icnp_grid(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_patient      => i_patient,
                                 i_episode      => i_episode,
                                 o_diag         => o_diag,
                                 o_interv       => o_interv,
                                 o_interv_presc => o_interv_presc);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
        
    END get_icnp_grid;

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
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_DIAGNOSIS_HIST';
    
    BEGIN
    
        g_current_operation := 'calling pk_icnp_fo.get_diagnosis_hist function';
        pk_icnp_fo.get_diagnosis_hist(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_diag    => i_diag,
                                      i_episode => i_episode,
                                      o_diag    => o_diag,
                                      o_r_diag  => o_r_diag);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_r_diag);
            RETURN FALSE;
        
    END get_diagnosis_hist;

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
    ) RETURN BOOLEAN IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_INTERV_HIST';
    
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_interv_hist function';
        pk_icnp_fo.get_interv_hist(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_patient           => i_patient,
                                   i_interv            => i_interv,
                                   i_reports           => pk_alert_constant.g_yes,
                                   o_interv_curr       => o_interv_curr,
                                   o_interv            => o_interv,
                                   o_epis_doc_register => o_epis_doc_register,
                                   o_epis_document_val => o_epis_document_val);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang, c_func_name, o_error);
            pk_types.open_my_cursor(o_interv_curr);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_epis_doc_register);
            pk_types.open_my_cursor(o_epis_document_val);
            RETURN FALSE;
        
    END get_interv_hist;

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
    ) RETURN VARCHAR2 IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_INTERV_ASSOC_DIAG_DESC';
    
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_interv_assoc_diag_desc function';
        RETURN pk_icnp_fo.get_interv_assoc_diag_desc(i_lang => i_lang, i_epis_interv => i_epis_interv);
    
    END get_interv_assoc_diag_desc;

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
    ) RETURN sys_message.desc_message%TYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_INTERV_ASSOC_DIAG_DESC';
    
    BEGIN
        g_current_operation := 'calling pk_icnp_fo.get_interv_instructions function';
        RETURN pk_icnp_fo.get_interv_instructions(i_lang => i_lang, i_prof => i_prof, i_interv => i_interv);
    
    END get_interv_instructions;

BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_fo_api_reports;
/
