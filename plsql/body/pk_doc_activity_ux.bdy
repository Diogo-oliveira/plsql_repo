/*-- Last Change Revision: $Rev: 2026993 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:40 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_doc_activity_ux IS

    FUNCTION param_list_to_clob(i_param_list IN t_param_list) RETURN CLOB IS
    
        l_final_clob CLOB;
        l_code_param VARCHAR(200 CHAR);
    
        l_param_list_separator VARCHAR2(3 CHAR) := '#{&';
        l_param_separator      VARCHAR2(3 CHAR) := '#|&';
    
    BEGIN
    
        g_error      := 'Start converting';
        l_final_clob := empty_clob();
    
        FOR i IN 1 .. i_param_list.count
        LOOP
            SELECT nvl(pk_translation.get_translation(2, dap.code_param), dap.code_param)
              INTO l_code_param
              FROM doc_act_param dap
             WHERE dap.param_name = i_param_list(i).param_name;
        
            --l_final_clob:=      
            l_final_clob := concat(concat(concat(concat(concat(l_final_clob, to_clob(i_param_list(i).param_name)),
                                                        to_clob(l_param_separator)),
                                                 to_clob(l_code_param)),
                                          to_clob(l_param_separator)),
                                   to_clob(i_param_list(i).param_value));
        
            IF i < i_param_list.count
            THEN
                l_final_clob := concat(l_final_clob, to_clob(l_param_list_separator));
            END IF;
        END LOOP;
    
        dbms_output.put_line('Size of the Image is: ' || dbms_lob.getlength(l_final_clob));
    
        RETURN l_final_clob;
    
    END param_list_to_clob;

    FUNCTION get_doc_activity
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc          IN NUMBER,
        o_doc_activity    OUT pk_types.cursor_type,
        o_param_separator OUT VARCHAR2,
        o_desc_separator  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_param_list_separator VARCHAR2(3 CHAR) := '#{&';
        l_param_separator      VARCHAR2(3 CHAR) := '#|&';
    
        doc_activity t_doc_activity_list;
    
    BEGIN
        o_param_separator := l_param_list_separator;
        o_desc_separator  := l_param_separator;
        g_error           := 'Getting document';
        IF NOT pk_doc_activity.get_doc_activity(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_doc       => i_id_doc,
                                                o_doc_activity => doc_activity,
                                                o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'Converting type in a cursor';
        OPEN o_doc_activity FOR
            SELECT da.professional_name,
                   da.id_professional,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => da.dt_operation_tstz,
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) --|| ' ' ||
                   --pk_date_utils.date_char_hour_tsz(i_lang => i_lang,
                                                    --i_date => da.dt_operation_tstz,
                                                    --i_inst => i_prof.institution,
                                                    --i_soft => i_prof.software) 
													dt_operation,
                   da.dt_operation_tstz,
                   da.operation_desc,
                   da.operation_name,
                   da.id_institution,
                   da.institution_name,
                   da.id_doc,
                   da.code_source,
                   da.source_desc,
                   da.code_target,
                   da.target_desc,
                   nvl(param_list_to_clob(da.parameters_list), empty_clob()) PARAMETERS
              FROM TABLE(doc_activity) da;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            g_error := SQLCODE || ' ' || SQLERRM;
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
        
            RETURN FALSE;
    END get_doc_activity;
	
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
    RETURN BOOLEAN IS
    
    BEGIN
      
      IF NOT pk_doc_activity.log_document_activity(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_doc_id       => i_doc_id,
                                                i_operation    => i_operation,
                                                i_source       => i_source,
                                                i_target       => i_target,
                                                i_status       => i_status,
                                                i_operation_param => i_operation_param,
                                                o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
      
      RETURN TRUE;
      
      EXCEPTION
        WHEN OTHERS THEN
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            g_error := SQLCODE || ' ' || SQLERRM;
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);

            RETURN FALSE;
      
    END log_open_document_activity;

BEGIN

    -- Log init
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_doc_activity_ux;
/
