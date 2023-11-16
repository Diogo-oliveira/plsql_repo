/*-- Last Change Revision: $Rev: 2028608 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_discharge_api_rep IS

    -- Author  : JOSE.SILVA
    -- Created : 03-03-2010 14:52:11
    -- Purpose : API to be used by the interfaces team in the discharge area

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /********************************************************************************************
    * Get the administrative discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_admin_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get all discharge notes (medical or administrative).
    *
    * @param i_lang               Language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_discharge       Discharge ID
    * @param i_flg_type           (A) Administrative or (D) Medical discharge notes
    * @param o_notes              The notes
    * @param o_error              Error message
    *
    * @return            TRUE if sucessful, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    **********************************************************************************************/
    FUNCTION get_disch_prof_notes
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_discharge    IN discharge.id_discharge%TYPE,
        i_flg_type        IN VARCHAR2,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_notes           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves a discharge record history of operations, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param o_hist                  cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_hist_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_disch           IN discharge.id_discharge%TYPE,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_hist            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve discharges, in ambulatory products. Adapted from GET_DISCHARGE.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_discharges_amb
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (admission)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_admit
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (transfer)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_transf
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (expired)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_expir
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (against medical advice)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_ama
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Devolve o detalhe da alta
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    **********************************************************************************************/
    FUNCTION get_disch_detail_disch
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail (left without being seen)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail_lwbs
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    -- 
    /********************************************************************************************
    * Returns discharge detail
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_disch_detail
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_discharge    IN NUMBER,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the episode discharge records
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    * @param   i_category_type       Professional category/discharge type
    *
    * @param   o_disch               Discharge records
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_discharge
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN discharge.id_episode%TYPE,
        i_prof            IN profissional,
        i_category_type   IN category.flg_type%TYPE,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the detail of a discharge record
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_disch               discharge ID
    * @param   i_prof                professional, institution and software ids
    *
    * @param   o_disch               Discharge record
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 2.5.1.8
    * @since   20-10-2011
    ********************************************************************************************/
    FUNCTION get_discharge_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_disch           IN discharge.id_discharge%TYPE,
        i_prof            IN profissional,
        i_fltr_start_date IN VARCHAR2,
        i_fltr_end_date   IN VARCHAR2,
        o_disch           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

END pk_discharge_api_rep;
/
