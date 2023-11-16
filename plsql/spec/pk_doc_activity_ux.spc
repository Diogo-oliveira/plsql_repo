/*-- Last Change Revision: $Rev: 2028618 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:56 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_doc_activity_ux IS

    /**
    * Functon that converts a param list to a clob
    *
    * @param i_param_list              id t_param_list
    *
    * @return                    Return CLOB
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */

    FUNCTION param_list_to_clob(i_param_list IN t_param_list) RETURN CLOB;

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
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc          IN NUMBER,
        o_doc_activity    OUT pk_types.cursor_type,
        o_param_separator OUT VARCHAR2,
        o_desc_separator  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
	
	/**
	* Log open activity on the document
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
	* @author        andre.silva
	* @version       1
	* @since         26/10/2016
	*/
	FUNCTION log_open_document_activity(i_lang            IN NUMBER,
									 i_prof            IN profissional,
									 i_doc_id          IN NUMBER,
									 i_operation       IN VARCHAR2,
									 i_source          IN VARCHAR2,
									 i_target          IN VARCHAR2,
									 i_status          IN VARCHAR2 DEFAULT 'S',
									 i_operation_param IN T_PARAM_LIST,
									 o_error           OUT t_error_out)
	RETURN BOOLEAN;

    -- Log variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_error VARCHAR2(4000);

END pk_doc_activity_ux;
/
