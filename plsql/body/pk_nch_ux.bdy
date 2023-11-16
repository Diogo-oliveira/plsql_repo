/*-- Last Change Revision: $Rev: 2027377 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_nch_ux IS

    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(10) := 'PK_NCH_UX';
    g_error         VARCHAR2(2000);

    /********************************************************************************************
    * Returns information of the NCH of an episode to be displayed in the viewer. 
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PBL FUNCTION';
        IF NOT pk_nch_pbl.get_epis_nch_viewer(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_epis  => i_epis,
                                              o_data  => o_data,
                                              o_error => o_error)
        THEN
            RETURN FALSE;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_NCH_VIEWER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_epis_nch_viewer;

    /**********************************************************************************************
    * Returns the total nch value allocated to a patient, at a given date.
    *
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
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
    ) RETURN NUMBER IS
        l_ret PLS_INTEGER;
        l_err t_error_out;
    BEGIN
    
        g_error := 'CALL PBL FUNCTION';
        RETURN pk_nch_pbl.get_nch_total(i_lang => i_lang,
                                        i_prof => i_prof,
                                        i_epis => i_epis,
                                        i_date => current_timestamp);
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_LEVELS',
                                              l_err);
            RETURN NULL;
    END get_nch_total;

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
    ) RETURN BOOLEAN IS
        l_err t_error_out;
    BEGIN
    
        g_error := 'CALL PBL FUNCTION';
        RETURN pk_nch_pbl.get_nch_estimated(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_flg_context => i_flg_context,
                                            i_id_context  => i_id_context,
                                            o_value       => o_value,
                                            o_error       => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_ESTIMATED',
                                              l_err);
            RETURN NULL;
    END get_nch_estimated;

END pk_nch_ux;
/
