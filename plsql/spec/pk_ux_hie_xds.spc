/*-- Last Change Revision: $Rev: 2029032 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ux_hie_xds IS
    -- Author  : ARIEL.MACHADO
    -- Created : 24-Nov-09 12:23:27 PM
    -- Purpose : ALERT Integration with HIE XDS Repository: user interface functions

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
    * @param i_doc_external              Document identifier
    * @param o_document_info             Document's details
    * @param o_error                     Error message
    
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
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
    * @param i_doc_external              Document identifier
    * @param i_conf_level                Confidentiality level ID 
    * @param o_xds_document_submission   Submmision ID
    * @param o_error                     Error message
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   24-Nov-09
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

END pk_ux_hie_xds;
/
