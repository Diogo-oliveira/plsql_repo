/*-- Last Change Revision: $Rev: 2028470 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_external_doc IS

    FUNCTION set_external_doc_tmp
    (
        i_doc_xml IN external_doc_tmp.doc_xml%TYPE,
        o_doc_xml OUT external_doc_tmp.doc_xml%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_external_doc
    (
        i_id_external_doc IN external_doc.id_external_doc%TYPE,
        i_id_ext          IN external_doc.id_ext%TYPE,
        i_name_ext        IN external_doc.name_ext%TYPE,
        i_dt_exec_ext     IN external_doc.dt_exec_ext%TYPE,
        i_doc_ext         IN external_doc.doc_ext%TYPE,
        i_flg_state       IN external_doc.flg_state%TYPE,
        o_doc_ext         OUT external_doc.doc_ext%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_error        VARCHAR2(200);
    g_package_name VARCHAR2(200);

    g_exception EXCEPTION;
    g_user_exception EXCEPTION;

END pk_api_external_doc;
/
