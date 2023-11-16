/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE pk_doc_global_search IS
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
    ) RETURN t_trl_trs_result;

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
    );

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
    ) RETURN t_trl_trs_result;

    g_doc_active     CONSTANT doc_external.flg_status%TYPE := 'A';
    g_doc_inactive   CONSTANT doc_external.flg_status%TYPE := 'I';
    g_doc_pendente   CONSTANT doc_external.flg_status%TYPE := 'P';
    g_doc_oldversion CONSTANT doc_external.flg_status%TYPE := 'O';

END pk_doc_global_search;
/
