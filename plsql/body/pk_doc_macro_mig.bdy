/*-- Last Change Revision: $Rev: 2027001 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc_macro_mig IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Migration of all prefilled templates that were created by an institution using a specific template whenever the template is replaced by another.
    *
    * @param   i_lang           Language
    * @param   i_institution    Institution where the prefilled templates were created and that will be migrated
    * @param   i_from_template  Original template ID that was used in the creation of prefilled templates
    * @param   i_to_template    Template ID which replaces the previous one and will be used for the migration of prefilled templates
    *
    * @param   o_error          Error information
    *
    * @return  True or False on sucess or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.3
    * @since   1/24/2013 5:08:42 PM
    */
    FUNCTION mig_inst_macros
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_from_template IN doc_template.id_doc_template%TYPE,
        i_to_template   IN doc_template.id_doc_template%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'mig_inst_macros';
    
        CURSOR c_macro_to_migrate IS
            SELECT dm.id_doc_macro
              FROM doc_macro dm
             INNER JOIN doc_macro_version dmv
                ON dm.id_doc_macro_version = dmv.id_doc_macro_version
             WHERE dm.id_institution = i_institution
               AND dm.flg_status IN (pk_doc_macro.g_dcm_flg_status_active, pk_doc_macro.g_dcm_flg_status_pending)
               AND dmv.flg_status = pk_doc_macro.g_dcmv_flg_status_active
               AND dmv.id_doc_template = i_from_template
               AND EXISTS (SELECT 1
                      FROM doc_template_update dtu
                     WHERE dtu.id_doc_area = dmv.id_doc_area
                       AND dtu.id_doc_template_source = dmv.id_doc_template
                       AND dtu.id_doc_template_target = i_to_template);
    
        l_lst_macro_to_migrate table_number;
        l_idx                  PLS_INTEGER;
        l_ret                  BOOLEAN;
    
    BEGIN
        g_error := 'Migration of prefilled templates created by institution:' || to_char(i_institution) || chr(10);
        g_error := g_error || 'From template: ' || to_char(i_from_template) || chr(10);
        g_error := g_error || 'To template: ' || to_char(i_to_template);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        OPEN c_macro_to_migrate;
        FETCH c_macro_to_migrate BULK COLLECT
            INTO l_lst_macro_to_migrate;
        CLOSE c_macro_to_migrate;
    
        l_idx := l_lst_macro_to_migrate.first;
        WHILE l_idx IS NOT NULL
        LOOP
            g_error := 'Migration of prefilled template (id_doc_macro = ' || to_char(l_lst_macro_to_migrate(l_idx)) ||
                       ') to use template ' || to_char(i_to_template);
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        
            l_ret := pk_doc_macro.set_migrate_macro(i_lang        => i_lang,
                                                    i_doc_macro   => l_lst_macro_to_migrate(l_idx),
                                                    i_to_template => i_to_template,
                                                    o_error       => o_error);
        
            IF l_ret = FALSE
            THEN
                g_error := 'ERROR - ' || g_error || chr(10) || 'SET_MIGRATE_MACRO returned an error.';
                g_error := g_error || ' ERRM: ' || o_error.ora_sqlerrm || ' ERR_DESC: ' || o_error.err_desc;
                pk_alertlog.log_error(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => k_function_name);
            ELSE
                g_error := 'SUCEESS - ' || g_error;
                pk_alertlog.log_info(text            => g_error,
                                     object_name     => g_package_name,
                                     sub_object_name => k_function_name);
            END IF;
        
            l_idx := l_lst_macro_to_migrate.next(l_idx);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END mig_inst_macros;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    pk_alertlog.log_init(g_package_name);
END pk_doc_macro_mig;
/
