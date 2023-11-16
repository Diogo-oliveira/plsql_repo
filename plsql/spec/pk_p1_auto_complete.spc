/*-- Last Change Revision: $Rev: 2028829 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:12 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_p1_auto_complete AS

    /**
    * Validates if user is active
    *
    * @param   i_inst_code   institution.ext_code%TYPE,
    * @param   i_prof_number professional.num_order%TYPE,
    * @param   i_pass        VARCHAR2,
    * @param   o_error error
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   10-12-2007
    */
    FUNCTION validate_user
    (
        i_inst_code   institution.ext_code%TYPE,
        i_prof_number professional.num_order%TYPE,
        i_pass        VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return patient data
    *
    * @param   i_lang external request id
    * @param   i_id_ext_req external request id
    * @param   o_data patient data
    * @param   o_health_plan patient health plans    
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   11-12-2007
    */
    FUNCTION get_patient_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_session  IN VARCHAR2,
        o_data        OUT pk_types.cursor_type,
        o_health_plan OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

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
    * Return clinical data
    *
    * @param   i_lang external request id
    * @param   i_id_session session id
    * @param   o_data last record data
    * @param   o_problem problems,
    * @param   o_history personal history,
    * @param   o_family_history family history,
    * @param   o_exams executed exams,
    * @param   o_diagnosis diagnosis,    
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   11-12-2007
    * @modify  Ana Monteiro 2009/02/09 ALERT-11633
    */
    FUNCTION get_clinical_data_new
    (
        i_lang             IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN VARCHAR2,
        o_detail     OUT pk_types.cursor_type,
        o_text       OUT pk_types.cursor_type,
        o_problem    OUT pk_types.cursor_type,
        o_diagnosis  OUT pk_types.cursor_type,
        o_mcdt       OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_can_cancel       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Return the url used to access the application.
    * Used by the interface.
    *
    * @param   i_lang external request id
    * @param   i_id_ext_req external request id
    * @param   o_data last record data
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   15-05-2007
    */
    FUNCTION get_url
    (
        i_inst_code   institution.ext_code%TYPE,
        i_prof_number professional.num_order%TYPE,
        i_session     VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;

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
    * Gets the translation code for the provided icd code
    *
    * @param   i_lang   professional language id
    * @param   i_code   icpc2 code
    *
    * @RETURN  translation code if exists, NULL otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_icd_desc
    (
        i_lang LANGUAGE.id_language%TYPE,
        i_code diagnosis.code_icd%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets alert id for the icd code provided.
    *
    * @param   i_code   icpc2 code
    *
    * @RETURN  translation code if exists, NULL otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_icd_id(i_code diagnosis.code_icd%TYPE) RETURN NUMBER;

    /**
    * Gets alert parent id for the icd code provided.
    *
    * @param   i_code   icpc2 code
    *
    * @RETURN  translation code if exists, NULL otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-07-2009
    */
    FUNCTION get_icd_parent_id(i_code diagnosis.code_icd%TYPE) RETURN NUMBER;

    /**
    * Matchs patient Alert's and external system's id's.
    *
    * @param   i_lang professional language id
    * @param   i_prof        Professional  id, institution and software
    * @param   i_patient     Patient identifier
    * @param   i_id_session  Session identifier    
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   21-12-2007
    */
    FUNCTION set_match
    (
        i_lang       IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_id_session   IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_p1_auto_complete;
/
