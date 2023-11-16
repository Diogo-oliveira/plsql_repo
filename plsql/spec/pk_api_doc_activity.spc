/*-- Last Change Revision: $Rev: 2028468 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:59 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_api_doc_activity IS

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
    RETURN BOOLEAN;

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
    RETURN BOOLEAN;

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
    RETURN BOOLEAN;

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
                            o_error        OUT t_error_out) RETURN BOOLEAN;

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
                            o_error        OUT t_error_out) RETURN BOOLEAN;

  -- Log variables
  g_package_owner VARCHAR2(50);
  g_package_name  VARCHAR2(50);

END pk_api_doc_activity;
/
