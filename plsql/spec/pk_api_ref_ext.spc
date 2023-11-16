/*-- Last Change Revision: $Rev: 1556846 $*/
/*-- Last Change by: $Author: joao.sa $*/
/*-- Date of last change: $Date: 2014-02-12 17:12:34 +0000 (qua, 12 fev 2014) $*/

CREATE OR REPLACE PACKAGE pk_api_ref_ext IS

    /**
    * Converts year, month and day sting into normalized date string
    *
    * @param   y year
    * @param   m month
    * @param   d day   
    *
    * @RETURN  date string, NULL in case of error
    * @author  Joao Sa
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_date_str
    (
        y VARCHAR2,
        m VARCHAR2,
        d VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Transform history data into a string    
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_text            Text
    * @param   i_code_desc       Code description
    * @param   i_notes           Notes
    * @param   i_dt_begin        Begin date
    * @param   i_dt_end          End date
    * @param   i_parent          Parent    
    *
    * @RETURN  VARCHAR2 String
    * @author  Ana Monteiro
    * @version 2.5
    * @since   21-04-2010
    */
    FUNCTION history_list_to_text
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_text      IN VARCHAR2,
        i_code_desc IN VARCHAR2,
        i_notes     IN VARCHAR2,
        i_dt_begin  IN VARCHAR2,
        i_dt_end    IN VARCHAR2,
        i_parent    IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Transform diagnostic tests data into a string   
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_text            Text
    * @param   i_code_desc       Code description
    * @param   i_result          Result tests
    * @param   i_dt              Tests date    
    *
    * @RETURN  VARCHAR2 String
    * @author  Ana Monteiro
    * @version 2.5
    * @since   21-04-2010
    */
    FUNCTION exam_list_to_text
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_text      IN VARCHAR2,
        i_code_desc IN VARCHAR2,
        i_result    IN VARCHAR2,
        i_dt        IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Returns patient data from temporary table REF_EXT_XML_DATA.
    * This data is stored on XML format. 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_session     Session identifier
    * @param   o_data           Patient data
    * @param   o_health_plan    Patient health plans
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-04-2010
    */
    FUNCTION get_patient_data
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_session  IN ref_ext_session.id_session%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_health_plan OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns referral data (must be synchronized with function PK_REF_CORE.get_referral) 
    *
    * @param   i_lang                         Language associated to the professional executing the request
    * @param   i_prof                         Professional, institution and software ids
    * @param   i_id_session                   Session identifier
    * @param   o_detail                       Referral general data
    * @param   o_text                         Referral detail data
    * @param   o_problem                      Patient problems to be addressed
    * @param   o_diagnosis                    Referral diagnosis
    * @param   o_mcdt                         Referral MCDT details
    * @param   o_needs                        Referral additional needs: Sent to registrar
    * @param   o_info                         Referral additional needs: Additional information    
    * @param   o_notes_status                 Referral tracking status    
    * @param   o_notes_status_det             Referral tracking status details
    * @param   o_answer                       Referral answer   
    * @param   o_can_cancel                   Flag indicating if referral can be canceled by the professional
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   20-04-2010
    */
    FUNCTION get_referral_data
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_session       IN ref_ext_session.id_session%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_can_cancel       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Validates if the session is valid. Returns professional data.
    *
    * @param   i_id_session    Session identifier
    * @param   o_professional  Professional identifier
    * @param   o_user          Professional login
    * @param   o_language      Professional language identifier
    * @param   o_institution   Institution identifier
    * @param   o_software      Software identifier
    * @param   o_error         Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   13-07-2010
    */
    FUNCTION validate_session
    (
        i_id_session   IN VARCHAR2,
        o_professional OUT professional.id_professional%TYPE,
        o_user         OUT ab_user_info.login%TYPE,
        o_language     OUT LANGUAGE.id_language%TYPE,
        o_institution  OUT institution.id_institution%TYPE,
        o_software     OUT software.id_software%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    ------------------------------------------------------------------------------
    -- Input data
    ------------------------------------------------------------------------------

    /**
    * Creates a new session identifier
    *
    * @param   i_lang           Language associated to the professional executing the request                  
    * @param   i_pass           Confidence data
    * @param   i_num_order      Professional order number
    * @param   i_ext_code       Intitution external code
    * @param   o_session_id     Session identifier        
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   29-04-2010
    */
    FUNCTION get_session_id
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_pass       IN VARCHAR2,
        i_num_order  IN professional.num_order%TYPE,
        i_ext_code   IN institution.ext_code%TYPE,
        o_session_id OUT ref_ext_session.id_session%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Saves patient and referral temporary data
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_patient_data   Patient temporary data (xml format)
    * @param   i_referral_data  Referral temporary data (xml format)
    * @param   o_ref_url        Temporary URL
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   29-04-2010
    */
    FUNCTION set_temp_data
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_id_session    IN ref_ext_xml_data.id_session%TYPE,
        i_patient_data  IN ref_ext_xml_data.patient_data%TYPE,
        i_referral_data IN ref_ext_xml_data.referral_data%TYPE,
        o_ref_url       OUT ref_ext_session.ref_url%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if referral original institution is private or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_session    Session identifier that is related to referral temporary data    
    * @param   o_flg_result    Flag indicating if this institution is private or not
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-07-2010
    */
    FUNCTION check_priv_orig_inst
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_session.id_session%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if referral is being updated, or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_session    Session identifier that is related to referral temporary data    
    * @param   o_flg_result    {*} Y - referral is being updated {*} N - referral is being created
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-07-2010
    */
    FUNCTION check_ref_update
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_session.id_session%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This functions updates session table after the referral has been created and notifies INTER-ALERT that the referral was updated
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been created
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   18-05-2010
    */
    FUNCTION set_ref_created
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This functions notifies INTER-ALERT that the referral was updated
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been updated
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   15-07-2010
    */
    FUNCTION set_ref_updated
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This is called by flash, to ping session identifier
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been updated
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   23-11-2010
    */
    FUNCTION session_ping
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    ------------------------------------------------------------------------------
    -- Job procedures (bulk operations)
    ------------------------------------------------------------------------------

    /**
    * Gets expire date based on i_date
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_date           Session creation date    
    *
    * @RETURN  Session expire date
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-07-2010
    */
    FUNCTION get_dt_expire
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_prof IN profissional,
        i_date IN ref_ext_session.dt_session%TYPE
    ) RETURN ref_ext_session.dt_session%TYPE;

    /**
    * Cleans inactive sessions have existed for some time
    *
    * @param   i_lang             Language
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-05-2010
    */
    PROCEDURE clean_ref_session(i_lang IN LANGUAGE.id_language%TYPE);

    /**
    * Sets sessions status to inactive
    *
    * @param   i_lang             Language
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-05-2010
    */
    PROCEDURE inactive_ref_session(i_lang IN LANGUAGE.id_language%TYPE);

END pk_api_ref_ext;
/
