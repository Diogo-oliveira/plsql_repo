/*-- Last Change Revision: $Rev: 2027837 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_hie_xds IS
    g_package_name  VARCHAR2(32 CHAR);
    g_package_owner VARCHAR2(32 CHAR);
    g_error         VARCHAR2(4000 CHAR);

    FUNCTION get_available_documents
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_documents OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_hie_xds.get_available_documents(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_episode   => i_episode,
                                                  o_documents => o_documents,
                                                  o_error     => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_AVAILABLE_DOCUMENTS');
                /* Open out cursors */
                pk_types.open_my_cursor(o_documents);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
    END get_available_documents;

    FUNCTION get_document_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_external  IN doc_external.id_doc_external%TYPE,
        o_document_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hie_xds.get_document_info(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_doc_external  => i_doc_external,
                                            o_document_info => o_document_info,
                                            o_error         => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOCUMENT_INFO');
                /* Open out cursors */
                pk_types.open_my_cursor(o_document_info);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
    END get_document_info;

    FUNCTION get_confidentiality_levels
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_conf_levels OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hie_xds.get_confidentiality_levels(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     o_conf_levels => o_conf_levels,
                                                     o_error       => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, '');
                /* Open out cursors */
                pk_types.open_my_cursor(o_conf_levels);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_confidentiality_levels;

    FUNCTION set_publish_document
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_doc_external            IN doc_external.id_doc_external%TYPE,
        i_conf_level              IN xds_confidentiality_level.id_xds_confidentiality_level%TYPE,
        o_xds_document_submission OUT xds_document_submission.id_xds_document_submission%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_hie_xds.set_publish_document(i_lang                    => i_lang,
                                               i_prof                    => i_prof,
                                               i_doc_external            => i_doc_external,
                                               i_conf_level              => i_conf_level,
                                               o_xds_document_submission => o_xds_document_submission,
                                               o_error                   => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_PUBLISH_DOCUMENT');
                /* Rollback changes */
                pk_utils.undo_changes();
                o_xds_document_submission := NULL;
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END set_publish_document;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_ux_hie_xds;
/
