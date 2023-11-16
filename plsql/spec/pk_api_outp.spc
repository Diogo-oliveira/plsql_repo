/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_outp IS

    -- Author  : ORLANDO.ANTUNES
    -- Created : 31-08-2010 09:42:03
    -- Purpose : This package contains Outpatient APIs to be used by the INTER-ALERT team.

    /******************************************************************************************************
    * Create an empty document with a temporary state and returns its ID.
    * The goal is to allow the attachment of images before the save final version of the document.
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   O_ID_DOC  created documment id
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Orlando Antunes
    * @version 1.0
    * @since   31-08-2010
    *****************************************************************************************************/
    FUNCTION create_initdoc
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN doc_external.id_patient%TYPE,
        i_episode IN doc_external.id_episode%TYPE,
        i_ext_req IN doc_external.id_external_request%TYPE,
        o_id_doc  OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    *
    * @return BOOLEAN
    *
    * @author Joel Lopes
    * @version 2.6.4.0
    * @since 2014-Jun-02
    ********************************************************************************************/
    FUNCTION get_mapping_problem_cda
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_source_codes         IN table_varchar,
        i_source_coding_scheme IN VARCHAR2,
        i_target_coding_scheme IN VARCHAR2,
        o_target_codes         OUT table_varchar,
        o_target_display_names OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    *
    * @return BOOLEAN
    *
    * @author Joel Lopes
    * @version 2.6.4.0
    * @since 2014-Jun-03
    ********************************************************************************************/
    FUNCTION set_problems_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_entries_to_add    IN t_tab_problem_cda,
        i_entries_to_edit   IN t_tab_problem_cda,
        i_entries_to_remove IN t_tab_problem_cda,
        i_cdr_call          IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_outp;
/
