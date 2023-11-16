/*-- Last Change Revision: $Rev: 2028841 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_p1_utils AS
    /**
    * Return last status change data for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_data last record data
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007
    */
    FUNCTION get_status_data
    (
        i_lang       IN NUMBER,
        i_id_ext_req IN NUMBER,
        i_flg_status IN VARCHAR2,
        o_data       OUT p1_tracking%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return last status date for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007
    */
    FUNCTION get_status_date
    (
        i_lang       IN NUMBER,
        i_id_ext_req IN NUMBER,
        i_flg_status IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /**
    * Return first status date for the request
    *
    * @param   i_id_ext_req external request id
    * @param   i_flg_status status
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-03-2009
    */
    FUNCTION get_first_status_date
    (
        i_lang       IN NUMBER,
        i_id_ext_req IN NUMBER,
        i_flg_status IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /**
    * Return last triage status (either 'T' or 'R')
    *
    * @param   i_exr_row external request data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   20-12-2007
    */
    FUNCTION get_last_triage_status(i_exr_row IN p1_external_request%ROWTYPE) RETURN p1_tracking%ROWTYPE;

    /**
    * Return last triage status (either 'T' or 'R')
    *
    * @param   i_id_ext_req external request id
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   20-12-2007
    */
    FUNCTION get_last_triage_status(i_id_ext_req IN NUMBER) RETURN p1_tracking%ROWTYPE;

    /**
    * Checks if provided timestamp is today
    *
    * @param   i_prof request id
    *
    * @RETURN  'Y' if TRUE, 'N' otherwise
    * @author  João Sá
    * @version 1.0
    * @since   06-01-2007
    */
    FUNCTION is_today
    (
        i_prof IN profissional,
        dt     IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR;

    /**
    * Get id_codification
    *
    * @param i_lang                       professional language
    * @param i_prof                       professional id, institution and software
    * @param i_ref_type                   referral type
    * @param i_mcdt_codification          id from the mcdt codifications
    * @param o_codification               id codifications
    * @param o_error         
    * 
    * @value i_ref_type {*}'A' Analyis {*}'E' Exams {*}'I' Image {*}'P' Interventions {*}'F' fisiatrics
    * @return                             TRUE if sucess, FALSE otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   03-09-2009
    */

    FUNCTION get_codification
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_ref_type          IN p1_external_request.flg_type%TYPE,
        i_mcdt_codification IN analysis_codification.id_analysis_codification%TYPE,
        o_codification      OUT codification.id_codification%TYPE,
        o_error             OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**
    * Return last status change date for the request except for the update
    *
    * @param   i_lang           Language identifier
    * @param   i_id_ref         Referral identifier
    * @param   i_flg_status     Referral flag status
    * @param   o_date           Last status change date
    * @param   o_error          Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   13-01-2010 
    */
    FUNCTION get_last_status_date
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        o_date       OUT p1_tracking.dt_tracking_tstz%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_error         VARCHAR2(4000 CHAR);
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);
    g_exception EXCEPTION;
END pk_p1_utils;
/
