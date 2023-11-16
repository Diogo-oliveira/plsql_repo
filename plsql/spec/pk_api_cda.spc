/*-- Last Change Revision: $Rev: 2028464 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_cda IS

    -- Author  : Tiago Lourenço
    -- Created : 5-May-2011
    -- Purpose : Provide services to CDA generation

    /***********************************************************************
                            GLOBAL - Generic Functions
    ***********************************************************************/

    /********************************************************************************************
    * Get patient problems
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)  
    * @param i_scope                  Episode (E) / Patient (P) / Visit (V)
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_visit               Visit identifier
    * @param o_problems               Problems list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Tiago Lourenço
    * @version               2.6.1
    * @since                 5-May-2011
    ********************************************************************************************/
    FUNCTION get_pat_problems
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_problems   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient lab tests results
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)  
    * @param i_scope                  Episode (E) / Patient (P) / Visit (V)
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_visit               Visit identifier
    * @param o_serialized_analysis_columns
    * @param o_serialized_analysis_rows
    * @param o_serialized_analysis_values
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Tiago Lourenço
    * @version               2.6.1
    * @since                 5-May-2011
    ********************************************************************************************/
    FUNCTION get_pat_lab_tests_results
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_scope                       IN VARCHAR2,
        i_id_patient                  IN patient.id_patient%TYPE,
        i_id_episode                  IN episode.id_episode%TYPE,
        i_id_visit                    IN episode.id_episode%TYPE,
        o_serialized_analysis_columns OUT pk_types.cursor_type,
        o_serialized_analysis_rows    OUT pk_types.cursor_type,
        o_serialized_analysis_values  OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient allergies
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)  
    * @param i_scope                  Episode (E) / Patient (P) / Visit (V)
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_visit               Visit identifier
    * @param o_allergies              Allergies list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Tiago Lourenço
    * @version               2.6.1
    * @since                 5-May-2011
    ********************************************************************************************/
    FUNCTION get_pat_allergies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_allergies  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient surgical procedures
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)  
    * @param i_scope                  Episode (E) / Patient (P) / Visit (V)
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_visit               Visit identifier
    * @param o_surg_hist              Past Surgical history
    * @param o_interv                 Surgery interventions
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Tiago Lourenço
    * @version               2.6.1
    * @since                 5-May-2011
    ********************************************************************************************/
    FUNCTION get_pat_surgical_procedures
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_surg_hist  OUT pk_types.cursor_type,
        o_interv     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient medication
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)  
    * @param i_scope                  Episode (E) / Patient (P) / Visit (V)
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_visit               Visit identifier
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Tiago Lourenço
    * @version               2.6.1
    * @since                 5-May-2011
    ********************************************************************************************/
    FUNCTION get_pat_medication
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_medication OUT CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
END pk_api_cda;
/
