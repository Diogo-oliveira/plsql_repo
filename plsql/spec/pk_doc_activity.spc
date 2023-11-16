/*-- Last Change Revision: $Rev: 2028617 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:55 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_doc_activity IS

    TYPE doc_param_info IS RECORD(
        param_name   doc_operation_param.param_name%TYPE,
        param_id     doc_operation_param.id_doc_operation_param%TYPE,
        flg_required doc_op_target_param.flg_required%TYPE,
        param_value  CLOB);

    TYPE doc_param_list IS TABLE OF doc_param_info INDEX BY PLS_INTEGER;

    doc_external_oid sys_config.value%TYPE;

    g_flg_yes VARCHAR2(1 CHAR) := 'Y';
    g_flg_no  VARCHAR2(1 CHAR) := 'N';

    g_translation_trs_code_base VARCHAR2(200 CHAR) := 'DOC_ACTIVITY_PARAM.CODE_PARAM.';

    -- Log variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    -------------------------------------------------------------------------------------------------
    --
    --                                METHODS
    --
    -------------------------------------------------------------------------------------------------
    FUNCTION get_operation_description
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_operation_name IN VARCHAR2,
        i_target         IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Log activity on the document
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_doc_id            document id
    * @param i_operation         Operation code
    * @param i_source            Source code
    * @param i_target            Target code
    * @param i_status            Operation status
    * @param i_operation_param   Operation parameters
    * 
    * @value i_status            {*} 'P' Pending {*} 'A' Active
    * 
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION log_document_activity
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_doc_id          IN NUMBER,
        i_operation       IN VARCHAR2,
        i_source          IN VARCHAR2,
        i_target          IN VARCHAR2,
        i_status          IN VARCHAR2 DEFAULT 'S',
        i_operation_param IN t_param_list,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Delete last registered operation on the document
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_doc_id            document id
    * @param i_operation         Operation code
    * @param i_source            Source code
    * @param i_target            Target code
    * @param i_operation_param   Operation parameters
    * 
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION delete_document_activity
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_doc_id    IN NUMBER,
        i_operation IN VARCHAR2,
        i_source    IN VARCHAR2,
        i_target    IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Uptade registered activity status
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc_activity   Activity id
    * @param i_new_status        New status
    * @param i_source            Source code
    * @param i_target            Target code
    * @param i_operation_param   Operation parameters
    * 
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION update_doc_activity_status
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_activity IN NUMBER,
        i_new_status      IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_doc_activity_status
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_param      IN t_param,
        i_new_status IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get document activity
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param o_doc_activity      type with ocurred activity
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION get_doc_activity
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_doc       IN VARCHAR2,
        o_doc_activity OUT t_doc_activity_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get document activity
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_oid_doc           document oid
    * @param o_doc_activity      type with ocurred activity
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION get_doc_activity
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_oid_doc      IN VARCHAR2,
        o_doc_activity OUT t_doc_activity_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get sent emails with document
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param o_doc_activity      type with ocurred activity
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION get_sent_emails
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_doc       IN NUMBER,
        o_doc_activity OUT t_doc_activity_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_doc_activity;
/
