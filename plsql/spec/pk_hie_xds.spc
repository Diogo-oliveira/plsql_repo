/*-- Last Change Revision: $Rev: 2028719 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hie_xds IS
    -- Author  : ARIEL.MACHADO
    -- Created : 24-Nov-09 12:23:27 PM
    -- Purpose : ALERT Integration with HIE XDS Repository: core functions

    /********************************************************************************************
    * Get avaliable documents for publishing in XDS Repository
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param id_episode                  Episode ID
    * @param o_documents                 Document list
    * @param o_error                     Error message                       
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
    **********************************************************************************************/
    FUNCTION get_available_documents
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_documents OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get details about a document
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_doc_external              Document ID                       
    * @param o_document_info             Document's details
    * @param o_error                     Error message
    
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
    * @changed Rui Spratley 2.6.0.4 23-Sep-2010
    **********************************************************************************************/
    FUNCTION get_document_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_external  IN doc_external.id_doc_external%TYPE,
        o_document_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get available confidentiality levels to publish a document in XDS Repository
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param o_conf_levels               Confidentiality levels
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
    **********************************************************************************************/
    FUNCTION get_confidentiality_levels
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_conf_levels OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Publish a document in XDS Repository
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_doc_external              Document ID                       
    * @param i_conf_level                Confidentiality level ID 
    * @param o_xds_document_submission   Submmision ID
    * @param o_error                     Error message
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
    * @changed Rui Spratley 2.6.0.4 23-Sep-2010
    **********************************************************************************************/
    FUNCTION set_publish_document
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_doc_external            IN doc_external.id_doc_external%TYPE,
        i_conf_level              IN xds_confidentiality_level.id_xds_confidentiality_level%TYPE,
        o_xds_document_submission OUT xds_document_submission.id_xds_document_submission%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves the description for a confidentiality level ID
    *
    * @param i_lang                      Language ID
    * @param i_conf_level                Confidentiality level ID
    *                        
    * @return                            Description or null if it doesn't exist
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   26-Nov-09
    **********************************************************************************************/
    FUNCTION get_confidentiality_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_conf_level xds_confidentiality_level.id_xds_confidentiality_level%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Enables HIE XDS document sharing functionality
    * This function should be used only by configurations in order to enable the use of HIE XDS. 
    *
    * @param i_inst                      Institution ID
    * @param i_enabled                   Functionality enabled (True/False)
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   02-Dec-09
    **********************************************************************************************/
    FUNCTION set_xds_enabled
    (
        i_institution IN institution.id_institution%TYPE,
        i_enabled     IN BOOLEAN
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Submit a document for HIE - for internal use only
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Doc external identifier
    * @param i_conf_code                 Conf code
    * @param i_desc_conf_code            Conf code description
    * @param i_code_coding_schema        Conf code schema
    * @param i_conf_code_set             Conf code set
    * @param i_desc_conf_code_set        Conf code set description
    * @param i_flg_status                Flag status
    * @param i_xds_doc_submission        Document submission Id - if null then we will get from sequence
    *    
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   13-Oct-2010
    **********************************************************************************************/
    FUNCTION set_submit_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Submit a document for HIE - reports use only
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Doc external identifier
    * @param i_conf_code                 Conf code
    * @param i_desc_conf_code            Conf code description
    * @param i_code_coding_schema        Conf code schema
    * @param i_conf_code_set             Conf code set
    * @param i_desc_conf_code_set        Conf code set description
    * @param i_flg_status                Flag status
    * @param i_xds_doc_submission        Document submission Id - if null then we will get from sequence
    * @param i_value
    * @param i_currency
    * @param i_desc_item
    * @param i_flg_send_to_hie
    *    
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   13-Oct-2010
    **********************************************************************************************/
    FUNCTION set_submit_doc_for_reports
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        i_value              IN xds_document_submission.value%TYPE,
        i_currency           IN currency.id_currency%TYPE,
        i_desc_item          IN xds_document_submission.desc_item%TYPE,
        i_flg_send_to_hie    IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Submit a document for HIE - for internal use only
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Doc external identifier
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   07-Oct-2010
    **********************************************************************************************/
    FUNCTION set_submit_doc_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sends a report to HIE. Created in the scope of Transaction Model
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_epis_report               Episode report IdIN epis_report.id_epis_report%TYPE,
    * @param i_value                     Value of the submission
    * @param i_currency                  Currency of the submission
    * @param i_desc_item                 Item description (PHR / Report/ etc.)
    * @param i_flg_send_to_hie           Send to HIE Y/N
    * @param i_hie_type                  HIE Type Datacenter, Regional, etc
    *
    * @param o_xds_doc_submission        Document submission Id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   12-Oct-2010
    **********************************************************************************************/
    FUNCTION set_send_report_to_hie
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_report     IN epis_report.id_epis_report%TYPE,
        i_value           IN xds_document_submission.value%TYPE,
        i_currency        IN currency.id_currency%TYPE,
        i_desc_item       IN VARCHAR2,
        i_flg_send_to_hie IN VARCHAR2,
        i_hie_type        IN VARCHAR2,
        --
        o_xds_doc_submission IN OUT xds_document_submission.id_xds_document_submission%TYPE,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Send pending docs to HIE
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_patient                   Patient id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   12-Oct-2010
    **********************************************************************************************/
    FUNCTION set_send_pending_docs_to_hie
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_group IN institution_group.id_group%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel pending docs
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_patient                   Patient id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   12-Oct-2010
    **********************************************************************************************/
    FUNCTION cancel_pending_docs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return report transaction number
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_epis_report               Epis Report id
    * @param o_doc_submission_oid        Document submission OID
    * @param o_doc_submission            Document submission Id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   12-Oct-2010
    **********************************************************************************************/
    FUNCTION get_report_transaction_number
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_report        IN epis_report.id_epis_report%TYPE,
        o_doc_submission_oid OUT VARCHAR2,
        o_doc_submission     OUT xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return xds document submission from doc external
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Document external Id
    * @param o_xds_doc_submission        Document submission Id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   21-Oct-2010
    **********************************************************************************************/

    FUNCTION get_doc_sub_from_doc_ext
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        o_xds_doc_submission OUT xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return xds document submission from doc external
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Document external Id
    * @param o_error                     Error message
    *                        
    * @return                            Document submission Id
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   21-Oct-2010
    **********************************************************************************************/

    FUNCTION get_doc_sub_from_doc_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
    ) RETURN xds_document_submission.id_xds_document_submission%TYPE;

    /********************************************************************************************
    * Return update document submission
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_flg_status                Flag status
    * @param i_doc_external              Document external Id
    * @param i_xds_doc_submission        Document submission Id - if null we will read from doc_external id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   21-Oct-2010
    **********************************************************************************************/
    FUNCTION update_document_submission
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return institution group id (ADT)
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_institution               Institution Id
    * @param o_inst_group                Institution Group Id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   27-Oct-2010
    **********************************************************************************************/
    FUNCTION get_institution_group_adt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_inst_group  OUT institution_group.id_group%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return institution group id (ADT)
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_institution               Institution Id
    *                        
    * @return                            Institution group
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   27-Oct-2010
    **********************************************************************************************/
    FUNCTION get_institution_group_adt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Delist document from HIE
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Document external Id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   28-Oct-2010
    **********************************************************************************************/
    FUNCTION delist_doc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delist document from HIE
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Document external Id
    * @param i_do_commit                 Flag to do commit inside the function
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   28-Oct-2010
    **********************************************************************************************/
    FUNCTION delist_doc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_do_commit          IN BOOLEAN,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if a document was previously submited
    *
    * @param i_doc_external              Document external Id
    * @return                            True if was sent or False otherwise
    *
    * @author  Carlos Guilherme
    * @version 2.6.0.4
    * @since   07-Dez-2010
    **********************************************************************************************/
    FUNCTION has_doc_ext_been_published
    (
        i_id_doc_external IN doc_external.id_doc_external%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Submit a document to HIE, either as a new Document or has an update
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Document external Id
    * @param i_conf_code                 Conf code
    * @param i_desc_conf_code            Conf code description
    * @param i_code_coding_schema        Conf code schema
    * @param i_conf_code_set             Conf code set
    * @param i_desc_conf_code_set        Conf code set description
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Spratley
    * @version 2.6.0.4
    * @since   28-Oct-2010
    **********************************************************************************************/
    FUNCTION set_submit_or_upd_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set to indicate an error occured when trying to send a document to HIE
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Document external Id
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Carlos Guilherme
    * @version 2.6.0.5
    * @since   27-Dez-2010
    **********************************************************************************************/
    FUNCTION set_submit_doc_error
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    
    /* GLOBAL VARIABLES */
    g_flg_submission_status_p VARCHAR2(1) := 'P'; --Pending
    g_flg_submission_status_n VARCHAR2(1) := 'N'; --New
    g_flg_submission_status_u VARCHAR2(1) := 'U'; --Update
    g_flg_submission_status_d VARCHAR2(1) := 'D'; --Delist/Delete
    g_flg_submission_status_c VARCHAR2(1) := 'C'; --Canceled
    g_flg_submission_status_s VARCHAR2(1) := 'S'; --Sent
    g_flg_submission_status_x VARCHAR2(1) := 'X'; --Error
    --
    g_flg_send_to_hie_y VARCHAR2(1) := 'Y';
    g_flg_send_to_hie_n VARCHAR2(1) := 'N';
    --
    g_hie_type_d VARCHAR2(1) := 'D'; --Datacenter
    g_hie_type_r VARCHAR2(1) := 'R'; --Regional
    g_hie_type_n VARCHAR2(1) := 'N'; --None
    --
    g_has_phr_y VARCHAR2(1) := 'Y';
    g_has_phr_n VARCHAR2(1) := 'N';
    --
    g_subm_status_a VARCHAR2(1) := 'A'; --Active
    g_subm_status_i VARCHAR2(1) := 'I'; --Active

END pk_hie_xds;
/
