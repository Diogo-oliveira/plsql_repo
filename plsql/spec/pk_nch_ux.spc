/*-- Last Change Revision: $Rev: 2028808 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_nch_ux IS

    /********************************************************************************************
    * Returns information to be 
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_id_epis              Episode id
    * @param o_data                 Cursor containing the data to be returned to the UX.        
    * @param o_error                Error message
    *
    * @return                       True or false, according to if the execution completes successfully or not.
    *
    * @author                       RicardoNunoAlmeida 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_epis_nch_viewer
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the total nch value allocated to a patient, at a given date.
    *
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
    * @param i_bmng_allocation_bed           ID of the episode's bed allocation. (UNUSED atm, but could not remove due to time constraints)
    * @param i_date                          Reference date to check the episode's NCH value
    *
    * @return                                Number of NCH hours the episode is allocating, or NULL for error.
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_nch_total
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the estimated nch (in minutes) for a given context and institution
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param o_value                Estimated nch in minutes
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_estimated
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2,
        i_id_context  IN NUMBER,
        o_value       OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_nch_ux;
/
