/*-- Last Change Revision: $Rev: 2026676 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:33 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_api_doc_activity IS

  g_error VARCHAR2(2000);
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
  FUNCTION log_document_activity(i_lang            IN NUMBER,
                                 i_prof            IN profissional,
                                 i_doc_id          IN NUMBER,
                                 i_operation       IN VARCHAR2,
                                 i_source          IN VARCHAR2,
                                 i_target          IN VARCHAR2,
                                 i_status          IN VARCHAR2,
                                 i_operation_param IN t_param_list,
                                 o_error           OUT t_error_out)
    RETURN BOOLEAN IS
    l_result BOOLEAN;
  BEGIN
    g_error  := 'Log document activity';
    l_result := pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_doc_id          => i_doc_id,
                                                      i_operation       => i_operation,
                                                      i_source          => i_source,
                                                      i_target          => i_target,
                                                      i_status          => i_status,
                                                      i_operation_param => i_operation_param,
                                                      o_error           => o_error);
  
    COMMIT;
    return l_result;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_error := t_error_out(SQLCODE,
                             SQLERRM,
                             g_error,
                             null,
                             null,
                             null,
                             null,
                             null);
      pk_alertlog.log_error(text        => g_error,
                            object_name => g_package_name,
                            owner       => g_package_owner);
      RETURN FALSE;
  END log_document_activity;

  /**
  * Uptade registered activity status
  *
  * @param i_lang              language id
  * @param i_prof              professional, software and institution ids
  * @param i_id_doc_activity   Activity id
  * @param i_new_status        New status
  * @param i_operation_param   Operation parameters
  * 
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         21/05/2014
  */
  FUNCTION update_doc_activity_status(i_lang            IN NUMBER,
                                      i_prof            IN profissional,
                                      i_id_doc_activity IN NUMBER,
                                      i_new_status      IN VARCHAR2,
                                      o_error           OUT t_error_out)
    RETURN BOOLEAN IS
    l_result BOOLEAN;
  BEGIN
    g_error := 'Updating field';
    RETURN pk_doc_activity.update_doc_activity_status(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_doc_activity => i_id_doc_activity,
                                                      i_new_status      => i_new_status,
                                                      o_error           => o_error);
  
    COMMIT;
    RETURN l_result;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_error := t_error_out(SQLCODE,
                             SQLERRM,
                             g_error,
                             null,
                             null,
                             null,
                             null,
                             null);
      pk_alertlog.log_error(text        => g_error,
                            object_name => g_package_name,
                            owner       => g_package_owner);
      RETURN FALSE;
  END;

  /**
  * Uptade registered activity status based on a parameter that have to be unique
  *
  * @param i_lang              language id
  * @param i_prof              professional, software and institution ids
  * @param i_param             t_param with parameter and value
  * @param i_new_status        New status
  * @param i_operation_param   Operation parameters
  * 
  * @return                    Return BOOLEAN
  *
  * @author        jorge.costa
  * @version       1
  * @since         21/05/2014
  */
  FUNCTION update_doc_activity_status(i_lang       IN NUMBER,
                                      i_prof       IN profissional,
                                      i_param      IN t_param,
                                      i_new_status IN VARCHAR2,
                                      o_error      OUT t_error_out)
    RETURN BOOLEAN IS
    l_result BOOLEAN;
  BEGIN
    RETURN pk_doc_activity.update_doc_activity_status(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_param      => i_param,
                                                      i_new_status => i_new_status,
                                                      o_error      => o_error);
  
    COMMIT;
    RETURN l_result;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      o_error := t_error_out(SQLCODE,
                             SQLERRM,
                             g_error,
                             null,
                             null,
                             null,
                             null,
                             null);
      pk_alertlog.log_error(text        => g_error,
                            object_name => g_package_name,
                            owner       => g_package_owner);
      RETURN FALSE;
  END;

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
  FUNCTION get_doc_activity(i_lang         IN NUMBER,
                            i_prof         IN profissional,
                            i_id_doc       IN doc_external_hist.id_doc_external%TYPE,
                            o_doc_activity OUT t_doc_activity_list,
                            o_error        OUT t_error_out) RETURN BOOLEAN IS
  
  BEGIN
  
    g_error := 'Getting document history log';
    RETURN pk_doc_activity.get_doc_activity(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_id_doc       => i_id_doc,
                                            o_doc_activity => o_doc_activity,
                                            o_error        => o_error);
  
  EXCEPTION
    WHEN OTHERS THEN
      o_error := t_error_out(SQLCODE,
                             SQLERRM,
                             g_error,
                             null,
                             null,
                             null,
                             null,
                             null);
      pk_alertlog.log_error(text        => g_error,
                            object_name => g_package_name,
                            owner       => g_package_owner);
      RETURN FALSE;
  END get_doc_activity;

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
  FUNCTION get_doc_activity(i_lang         IN NUMBER,
                            i_prof         IN profissional,
                            i_oid_doc      IN VARCHAR2,
                            o_doc_activity OUT t_doc_activity_list,
                            o_error        OUT t_error_out) RETURN BOOLEAN IS
  
  BEGIN
  
    g_error := 'Getting document activity';
    RETURN pk_doc_activity.get_doc_activity(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_oid_doc      => i_oid_doc,
                                            o_doc_activity => o_doc_activity,
                                            o_error        => o_error);
  EXCEPTION
    WHEN OTHERS THEN
      o_error := t_error_out(SQLCODE,
                             SQLERRM,
                             g_error,
                             null,
                             null,
                             null,
                             null,
                             null);
      g_error := SQLCODE || ' ' || SQLERRM;
      pk_alertlog.log_error(text        => g_error,
                            object_name => g_package_name,
                            owner       => g_package_owner);
      RETURN FALSE;
  END get_doc_activity;

BEGIN
  -- Log init
  pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);

  pk_alertlog.log_init(owner       => g_package_owner,
                       object_name => g_package_name);

END pk_api_doc_activity;
/
