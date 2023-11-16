/*-- Last Change Revision: $Rev: 2028825 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_organ_donor AS

    --
    -- PUBLIC FUNCTIONS
    -- 

    /**********************************************************************************************
    * Set organ donor data
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_date                   Date of changes
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_data_val               Structure with all data values
    * @param        o_organ_donor            Organ donor id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        24-Jun-2010
    **********************************************************************************************/
    FUNCTION set_organ_donor
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_date        IN organ_donor.dt_organ_donor%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_data_val    IN table_table_varchar,
        o_organ_donor OUT organ_donor.id_organ_donor%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get organ donor data
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_status                 Registry status, if null returns with any status
    *                                        (defaults to null)
    * @param        o_data_val               Structure with all data values
    * @param        o_prof_data              Cursor with the professional data
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        25-Jun-2010
    **********************************************************************************************/
    FUNCTION get_organ_donor_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_status    IN death_registry.flg_status%TYPE DEFAULT NULL,
        o_data_val  OUT table_table_varchar,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get organ donor data history
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        o_data_val               Structure with all data values history
    * @param        o_prof_data              Cursor with the professional data history
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        25-Jun-2010
    **********************************************************************************************/
    FUNCTION get_organ_donor_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_data_val  OUT table_table_varchar,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel organ donor
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_date                   Cancel date
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_cancel_reason          Cancel reason id
    * @param        i_notes_cancel           Cancel notes
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        18-Jun-2010
    **********************************************************************************************/
    FUNCTION cancel_organ_donor
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN death_registry.dt_death_registry%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN death_registry.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_diagnosis              Cursor with diagnosis list for contagious diseases 
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the patient contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        o_diagnosis              Cursor with the patient diagnosis list for
    *                                        contagious diseases
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        09-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Changes the patient id in a organ donor registry (This function should only be called
    * by pk_api_edis.set_episode_new_patient or pk_match.set_match_all_pat_internal)
    *
    * @param        i_lang                   Language id
    * @param        i_new_patient            New patient id
    * @param        i_old_patient            Old patient id, if null searches for episode id
    *                                        (defaults to null)
    * @param        i_episode                Episode id, if null searches for old patient id
    *                                        (defaults to null)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        16-Jul-2010
    **********************************************************************************************/
    FUNCTION change_donor_patient_id
    (
        i_lang        IN language.id_language%TYPE,
        i_new_patient IN organ_donor.id_patient%TYPE,
        i_old_patient IN organ_donor.id_patient%TYPE DEFAULT NULL,
        i_episode     IN organ_donor.id_episode%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Changes the episode id in a organ donor registry (This function should only be called
    * by pk_match.set_match_core)
    *
    * @param        i_lang                   Language id
    * @param        i_new_episode            New episode id
    * @param        i_old_episode            Old episode id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        16-Jul-2010
    **********************************************************************************************/
    FUNCTION change_donor_episode_id
    (
        i_lang        IN language.id_language%TYPE,
        i_new_episode IN organ_donor.id_episode%TYPE,
        i_old_episode IN organ_donor.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_organ_donor;
/
