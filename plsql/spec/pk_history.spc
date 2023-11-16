/*-- Last Change Revision: $Rev: 2028720 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_history AS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_sysdate_tstz TIMESTAMP
        WITH LOCAL TIME ZONE;

    g_hist_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_hist_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_hist_cancel   CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_hist_outdated CONSTANT VARCHAR2(1 CHAR) := 'O';

    /**********************************************************************************************
    * GET_EPIS_COMPLETE_HISTORY       Returns all information active for complete history functionality
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param o_text                   The history text       
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          13-Nov-2006
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4 
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION get_all_epis_complete_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_text       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * GET_EPIS_COMPLETE_HISTORY       Returns the History id and text of a given id or episode
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_id_complete_history    History Record ID
    * @param o_text                   The history text       
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          13-Nov-2006
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4 
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION get_epis_complete_history
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_complete_history IN complete_history.id_complete_history%TYPE,
        o_text                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_EPIS_COMPLETE_HISTORY       Saves a register into the patient integrated history
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_text                   text to save in the patient history       
    * @param i_flg_action             Indicates the origin of the current registry ('N'-New registry; 'E'-Edited registry)
    * @param i_id_parent_ch           Id complete history used for update information
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0 
    * @since                          14-Jan-2007
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION set_epis_complete_history
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_text         IN complete_history.long_text%TYPE,
        i_flg_action   IN complete_history.flg_action%TYPE,
        i_id_parent_ch IN complete_history.id_parent%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_EPIS_COMPLETE_HISTORY       Saves a register into the patient integrated history
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_text                   text to save in the patient history       
    * @param i_flg_action             Indicates the origin of the current registry ('N'-New registry; 'E'-Edited registry)
    * @param i_id_parent_ch           Id complete history used for update information
    * @param i_dt_creation_tstz       date of creation of current registry
    * @param o_id_complete_history    Id of complete_history created
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Carlos Ferreira
    * @version                        1.0 
    * @since                          14-Jan-2007
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION set_epis_complete_history
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_text                IN complete_history.long_text%TYPE,
        i_flg_action          IN complete_history.flg_action%TYPE,
        i_id_parent_ch        IN complete_history.id_parent%TYPE,
        i_dt_creation_tstz    IN complete_history.dt_creation_tstz%TYPE,
        o_id_complete_history OUT complete_history.id_complete_history%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_MATCH_COMPLETE_HISTORY      Function used in match functionality to update Complete History date between episodes and patients.
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode_new         Destiny episode ID
    * @param i_id_episode_old         Origin episode ID
    * @param i_id_patient_new         Destiny patient ID
    * @param i_id_patient_old         Origin patient ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          2011/02/05
    **********************************************************************************************/
    FUNCTION set_match_complete_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode_new IN episode.id_episode%TYPE,
        i_id_episode_old IN episode.id_episode%TYPE,
        i_id_patient_new IN patient.id_patient%TYPE,
        i_id_patient_old IN patient.id_patient%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * GET_EPIS_CH_HIST                Gets epis complete history history or detail data
    *
    * @param i_lang                   the language ID
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             episode ID
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param o_hist                   History cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @version                        2.6.0.5.1.4
    * @since                          05-Feb-2011
    **********************************************************************************************/
    FUNCTION get_epis_ch_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_complete_history IN complete_history.id_complete_history%TYPE,
        i_flg_screen          IN VARCHAR2,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

END pk_history;
/
