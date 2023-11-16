/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_prev_encounter IS

    /**
    * Retrieve summarized descriptions on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param i_flg_type     {*} 'A' All Specialities {*} 'M' With me {*} 'S' My speciality    
    * @param o_enc_info     previous contacts descriptions
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/04/27
    *
    * @dependents           PK_PATIENT_SUMMARY.get_amb_dashboard 
    */
    FUNCTION get_prev_enc_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2 DEFAULT 'A',
        o_enc_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieve summarized info on all previous encounters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_enc_info     previous encounters info
    * @param o_enc_data     previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/03/31
    */
    FUNCTION get_prev_encounter
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_enc_info OUT pk_types.cursor_type,
        o_enc_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieve detailed info on previous encounter.
    * Information is SOAP oriented.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_soap_blocks  soap blocks
    * @param o_data_blocks  data blocks
    * @param o_simple_text  simple text blocks structure
    * @param o_doc_reg      documentation registers
    * @param o_doc_val      documentation values
    * @param o_free_text    free text records
    * @param o_rea_visit    reason for visit records
    * @param o_app_type     appointment type
    * @param o_prof_rec     author and date of last change
    * @param o_nur_data     previous encounter nursing data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/20
    */
    FUNCTION get_prev_encounter_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_soap_blocks OUT pk_types.cursor_type,
        o_data_blocks OUT pk_types.cursor_type,
        o_simple_text OUT pk_types.cursor_type,
        o_doc_reg     OUT pk_types.cursor_type,
        o_doc_val     OUT pk_types.cursor_type,
        o_free_text   OUT pk_types.cursor_type,
        o_rea_visit   OUT pk_types.cursor_type,
        o_app_type    OUT pk_types.cursor_type,
        o_prof_rec    OUT pk_translation.t_desc_translation,
        o_nur_data    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieve summarized info on the last encounter.
    * If the last encounter was cancelled, then it should also be presented.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      actual episode identifier
    * @param o_enc_data     previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2009/03/31
    *
    * @dependents           PK_PATIENT_SUMMARY.get_amb_dashboard 
    */
    FUNCTION get_last_encounter
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_enc_data OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the previous visits of a patient
    *
    * @param   i_lang        Language ID
    * @param   i_prof        Professional's details
    * @param   i_patient     ID patient
    * @param   i_episode     ID episode
    * @param   i_flg_type    type of visits M - My ; S - My speciality; A - All
    *
    * @return                True or False
    *
    * @author                Elisabete Bugalho
    * @version               2.6.2
    * @since                 2012/04/03   
    ********************************************************************************************/
    FUNCTION get_prev_visits
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2 DEFAULT 'A',
        o_enc_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the visit type 
    *
    * @param   i_lang        Language ID
    * @param   i_prof        Professional's details
    * @param   i_episode     ID episode
    * @param   i_epis_type   id epis_type
    *
    * @return                True or False
    *
    * @author                Elisabete Bugalho
    * @version               2.6.2
    * @since                 2012/04/05 
    ********************************************************************************************/
    FUNCTION get_visit_type_epis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_epis_type IN epis_type.id_epis_type%TYPE
    ) RETURN VARCHAR2;
END pk_prev_encounter;
/
