/*-- Last Change Revision: $Rev: 2026680 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_external_doc IS

    FUNCTION set_external_doc_tmp
    (
        i_doc_xml IN external_doc_tmp.doc_xml%TYPE,
        o_doc_xml OUT external_doc_tmp.doc_xml%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        INSERT INTO external_doc_tmp
            (doc_xml)
        VALUES
            (i_doc_xml)
        RETURNING doc_xml INTO o_doc_xml;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_external_doc_tmp;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        INSERT INTO external_doc
            (id_external_doc, id_ext, name_ext, dt_exec_ext, doc_ext, dt_insert, flg_state)
        VALUES
            (i_id_external_doc, i_id_ext, i_name_ext, i_dt_exec_ext, i_doc_ext, SYSDATE, i_flg_state)
        RETURNING doc_ext INTO o_doc_ext;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_external_doc;

BEGIN

    -- Log initialization
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_api_external_doc;
/
