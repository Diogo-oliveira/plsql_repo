/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_doc_global_search IS

    /**
    * Returns the patient and episode associated to a document.
    *
    * @param i_owner             table owner
    * @param i_table             table name
    * @param i_rowtype           table row
    *
    * @return t_trl_trs_result
    * @created 2013.12.02
    * @author jorge.costa
    */
    FUNCTION get_gs_ep_doc_external
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN doc_external%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
            SELECT i_rowtype.id_episode, i_rowtype.id_patient, i_rowtype.id_professional, i_rowtype.dt_inserted, NULL
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_rec';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_info_rec');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_gs_ep_doc_external;

    /**
    * Returns the translation of codified columns
    *
    * @param i_owner                   table owner
    * @param i_table                   table name
    * @param i_lang                    id language
    * @param i_rowtype                 table row
    * @param o_code_list               codified columns
    * @param o_desc_list               codified columns descriptions
    *
    * 
    * @created 2013.12.02
    * @author jorge.costa
    */
    PROCEDURE get_gs_codes_doc_external
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_rowtype   IN doc_external%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_record_dt  VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_DOC_ORI_TYPE.' ||
                                                i_rowtype.id_doc_external;
        l_code_record_dot VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_DOC_TYPE.' ||
                                                i_rowtype.id_doc_external;
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_codes_rec';
    
        codes alert_core_tech.table_varchar := alert_core_tech.table_varchar();
    
    BEGIN
        o_code_list := table_varchar();
        o_desc_list := table_varchar();
    
        IF (i_rowtype.flg_status IN (g_doc_active, g_doc_inactive))
        THEN
            o_code_list := table_varchar(l_code_record_dt, l_code_record_dot);
            o_desc_list := table_varchar(pk_translation.get_translation(i_lang,
                                                                        'DOC_TYPE.CODE_DOC_TYPE.' ||
                                                                        i_rowtype.id_doc_type),
                                         pk_translation.get_translation(i_lang,
                                                                        'DOC_ORI_TYPE.CODE_DOC_ORI_TYPE.' ||
                                                                        i_rowtype.id_doc_ori_type));
        END IF;
    
        -- In the case of the document was updated to 'outdated', the previous records must be removed
        IF (i_rowtype.flg_status = pk_doc.g_doc_oldversion)
        THEN
        
            SELECT c.owner || '.' || c.obj_name || '.' || c.column_name || '.' || to_char(i_rowtype.id_doc_external)
              BULK COLLECT
              INTO codes
              FROM frmw_obj_columns c
             WHERE c.obj_name = 'DOC_EXTERNAL'
               AND c.flg_global_search IN ('Y', 'C');
        
            pk_core_translation.delete_code_translation_trs(i_code => codes);
        
            -- In way to guarantee that the trigger don't re-insert the record, the lists with codes must be cleaned
            o_code_list := table_varchar();
            o_desc_list := table_varchar();
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
    END get_gs_codes_doc_external;

    /**
    * Returns the patient and episode associated to a document.
    *
    * @param i_owner             table owner
    * @param i_table             table name
    * @param i_rowtype           table row
    *
    * @return t_trl_trs_result
    * @created 2013.12.02
    * @author jorge.costa
    */
    FUNCTION get_gs_ep_doc_comments
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN doc_comments%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        
            SELECT doc.id_episode, doc.id_patient, i_rowtype.id_professional, i_rowtype.dt_comment, NULL
              FROM doc_external doc
             WHERE doc.id_doc_external = i_rowtype.id_doc_external;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_rec';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_info_rec');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_gs_ep_doc_comments;

END pk_doc_global_search;
/
