/*-- Last Change Revision: $Rev: 2028612 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_disposition_ux IS

    /**********************************************************************************************
    * Returns death event characterization data
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    *
    * @param o_death_evet          Content cursor
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Sergio Dias
    * @version                     2.6.3.15
    * @since                       Apr-3-2014
    **********************************************************************************************/
    FUNCTION get_death_event
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_death_event OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get discharge shortcut
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param o_discharge_shortcut  Discharge shortcut
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.4
    * @since                       Dec-15-2014
    **********************************************************************************************/
    FUNCTION get_discharge_shortcut
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_discharge_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_discharge           ID of discharge
    * @param i_episode             ID of episode
    * @param i_pat_pregnancy       ID of pat_pregnancy
    * @param i_flg_condition       Flag of newborn condition
    *
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Vanessa Barsottelli
    * @version                     2.7.0
    * @since                       10-11-2016
    **********************************************************************************************/
    FUNCTION set_newborn_discharge
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_discharge     IN discharge.id_discharge%TYPE,
        i_episode       IN table_number,
        i_pat_pregnancy IN table_number,
        i_flg_condition IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_name VARCHAR2(4000);

    g_error VARCHAR2(4000);

    g_sysdate DATE;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_exception EXCEPTION;

END pk_disposition_ux;
/
