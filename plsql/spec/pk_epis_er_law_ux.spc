/*-- Last Change Revision: $Rev: 2028680 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:17 +0100 (ter, 02 ago 2022) $*/



CREATE OR REPLACE PACKAGE pk_epis_er_law_ux IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 27-10-2011 08:32:40
    -- Purpose : Functions used in UX layer

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Create/Update episode emergency law record
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_dt_activation             Date of activation
    * @param   i_dt_inactivation           Date of inactivation
    * @param   i_flg_er_law_status         Emergency law status
    * @param   i_flg_create                only used for audit trail
    * @param   o_epis_er_law               Created/updated record PK id
    * @param   o_error                     Error information
    *
    * @values  i_flg_er_law_status         A - Active
    *                                      I - Inactive
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION set_epis_er_law
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN epis_er_law.id_episode%TYPE,
        i_dt_activation     IN VARCHAR2,
        i_dt_inactivation   IN VARCHAR2,
        i_flg_er_law_status IN epis_er_law.flg_er_law_status%TYPE,
        i_flg_create        IN VARCHAR2,
        o_epis_er_law       OUT epis_er_law.id_epis_er_law%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel episode emergency law record
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_cancel_notes              Cancel notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION cancel_epis_er_law
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN epis_er_law.id_episode%TYPE,
        i_cancel_reason IN epis_er_law.id_cancel_reason%TYPE,
        i_cancel_notes  IN epis_er_law.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get list of episode emergency law
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_lst_epis_er_law           List of episode emergency law
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_lst_epis_er_law
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN epis_er_law.id_episode%TYPE,
        o_lst_epis_er_law OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get episode emergency law record
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_er_law               Episode emergency law id
    * @param   o_epis_er_law               Episode emergency law record
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_epis_er_law
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_epis_er_law OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get emergency law date limits
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_limits                    List of date limits
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_date_limits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_er_law.id_episode%TYPE,
        o_limits  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get GES discharge message
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_flg_type                  Message type
    * @param   o_url                       URL to the external GES system
    * @param   o_total_unnot_pathologies   Total unnotified pathologies
    * @param   o_error                     Error information
    *
    * @values  o_flg_type                  N - No message to display
    *                                      W - Warning
    *                                      C - Confirmation
    *                                      E - Error
    *                                      WC - Warning and confirmation
    *                                      WE - Warning and error
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   27-10-2011
    */
    FUNCTION get_ges_discharge_msg
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN epis_ges_msg.id_episode%TYPE,
        o_flg_type                OUT VARCHAR2,
        o_url                     OUT VARCHAR2,
        o_total_unnot_pathologies OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
END pk_epis_er_law_ux;
/
