/*-- Last Change Revision: $Rev: 2029022 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_trauma_api_ui IS

    -- Author  : JOSE.BRITO
    -- Created : 22-06-2009 15:34:37
    -- Purpose : Trauma registration functions for FLASH

    -- Public function and procedure declarations
    --
    /**********************************************************************************************
    * Calculates Revised Trauma Score (RTS). 
    * IMPORTANT!! This function is for specific use by Announced Arrival (Dashboard)!!
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_vital_sign         Array with the vital signs ID
    * @param i_value              Array with the registered values
    * @param o_score              Revised Trauma Score
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_rts_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_vital_sign IN table_number,
        i_value      IN table_number,
        o_score      OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the available scores. Used by Flash to know how many blocks must be shown, 
    * one block for each score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID for each parameter
    * @param o_score              Cursor with the available scores
    * @param o_flg_detail         Activate the DETAIL button: (Y)es (N)o
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_score      OUT pk_types.cursor_type,
        o_flg_detail OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Shows all parameters for all scores.
    * Returns the parameters properties and current value.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_episode            Episode ID
    * @param i_id_epis_mtos_score Score ID (currently not needed)
    * @param o_list               Cursor with the parameters
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_param_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the history of scores for the current episode. Results shown in the detail screen.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param o_reg                Cursor with the scores
    * @param o_value              Cursor with the parameters and registered values
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_mtos_param_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_reg        OUT pk_types.cursor_type,
        o_value      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the total value for a given score.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      ID's of the score parameters
    * @param i_value              Registered values for each parameter
    * @param i_flg_score_type     Type of score
    * @param o_total              Cursor with the results
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_total_score
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_mtos_param  IN table_number,
        i_value          IN table_number,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        o_total          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the options for the parameters filled by multichoice.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_mtos_param      Parameter ID
    * @param i_flg_score_type     Type of score
    * @param i_id_patient         Patient ID
    * @param o_list               Cursor with the results
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION get_param_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_mtos_param  IN mtos_param.id_mtos_param%TYPE,
        i_flg_score_type IN mtos_score.flg_score_type%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Saves a score and all the registered values.
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_prof_cat           Professional category
    * @param i_id_episode         Episode ID
    * @param i_id_patient         Patient ID
    * @param i_id_mtos_param      Array of parameter ID's
    * @param i_value              Array with the registered values
    * @param i_unit_measure       Array with unit measures
    * @param o_flg_detail         Activate the DETAIL button: (Y)es (N)o
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/07/08
    **********************************************************************************************/
    FUNCTION set_mtos_score
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat      IN category.flg_type%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_mtos_param IN table_number,
        i_value         IN table_number,
        i_unit_measure  IN table_number,
        o_flg_detail    OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- Globals
    g_owner        VARCHAR2(200);
    g_package_name VARCHAR2(200);
    g_error        VARCHAR2(4000);

END pk_trauma_api_ui;
/
