/*-- Last Change Revision: $Rev: 2027003 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc_macro_ux IS

    -----------> STATIC VARIABLES <-----------
    g_error VARCHAR2(1000 CHAR);
    -- Package info
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    ---------> END STATIC VARIABLES <---------

    /********************************************************************************************
     * Get Products that contains areas and templates
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_products               List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    FUNCTION get_doc_products
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_products OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_products';
        l_error t_error_out;
    BEGIN
    
        pk_doc_macro.get_doc_products(i_lang => i_lang, i_prof => i_prof, o_products => o_products, o_error => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN FALSE;
    END get_doc_products;

    /********************************************************************************************
     * Get list of areas with templates for a specified product.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_product                Id of the product to get areas
     * @param o_areas                  List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    FUNCTION get_doc_areas
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_product IN software.id_software%TYPE,
        o_areas   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_areas';
        l_error t_error_out;
    BEGIN
    
        pk_doc_macro.get_doc_areas(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_doc_product => i_product,
                                   o_doc_areas   => o_areas,
                                   o_error       => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN FALSE;
    END get_doc_areas;

    /********************************************************************************************
     * Get list of templates for a specified product and area.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_product                Id of the product to get areas
     * @param i_area                   Id of the area to get templates
     * @param o_templates              List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    FUNCTION get_doc_templates
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_product   IN software.id_software%TYPE,
        i_area      IN doc_area.id_doc_area%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_templates';
        l_error t_error_out;
    BEGIN
    
        pk_doc_macro.get_doc_templates(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_doc_product   => i_product,
                                       i_doc_area      => i_area,
                                       o_doc_templates => o_templates,
                                       o_error         => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RETURN FALSE;
    END get_doc_templates;

    /*************************************************************************
    * Function used to create \ edit a template macro                        *
    *                                                                        *
    * @param i_lang               Preferred language ID for this professional*
    * @param i_prof               Object (professional ID, institution ID,   *
    *                             software ID)                               *
    * @param i_doc_area           Doc Area identifier                        *
    * @param i_doc_template       Doc template identifier                    *
    * @param i_macro_name         Doc macro name                             *
    * @param i_software_macro     List of softwares were macro applies       *
    * @param i_flg_status         Doc macro flag status(A-Active, I-Inactive)*
    * @param i_macro_notes        Doc macro notes                            *
    * @param i_doc_macro          Doc macro identifier (for edition)         *
    * @param i_flg_type           Action type                                *
    *                             (N - New, E-Edition, O-No changes)         *
    * @param i_documentation      Documentation list                         *
    * @param i_doc_element        Doc element list                           *
    * @param i_doc_element_crit   Doc element crit list                      *
    * @param i_dcmvd_value        Doc macro version detail values list       *
    * @param i_dcmv_notes         Doc macro version notes                    *
    * @param i_doc_element_qualif Doc element qualifiers list                *
    *                                                                        *
    * @return                   true or false on success or error            *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/01/19                                   *
    *************************************************************************/
    FUNCTION save_macro
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_macro_name         IN VARCHAR2,
        i_software_macro     IN table_number,
        i_flg_status         IN doc_macro.flg_status%TYPE,
        i_macro_notes        IN doc_macro.notes%TYPE,
        i_doc_macro          IN doc_macro.id_doc_macro%TYPE,
        i_flg_type           IN VARCHAR2,
        i_documentation      IN table_number,
        i_doc_element        IN table_number,
        i_doc_element_crit   IN table_number,
        i_dcmvd_value        IN table_varchar,
        i_dcmv_notes         IN doc_macro_version.notes%TYPE,
        i_doc_element_qualif IN table_table_number,
        o_doc_macro          OUT doc_macro.id_doc_macro%TYPE,
        o_doc_macro_version  OUT doc_macro_version.id_doc_macro_version%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'save_macro';
    BEGIN
        g_error := 'Call pk_doc_macro.save_macro';
        pk_doc_macro.save_macro(i_lang               => i_lang,
                                i_prof               => i_prof,
                                i_doc_area           => i_doc_area,
                                i_doc_template       => i_doc_template,
                                i_macro_name         => i_macro_name,
                                i_software_macro     => i_software_macro,
                                i_flg_status         => i_flg_status,
                                i_macro_notes        => i_macro_notes,
                                i_doc_macro          => i_doc_macro,
                                i_flg_type           => i_flg_type,
                                i_documentation      => i_documentation,
                                i_doc_element        => i_doc_element,
                                i_doc_element_crit   => i_doc_element_crit,
                                i_dcmvd_value        => i_dcmvd_value,
                                i_dcmv_notes         => i_dcmv_notes,
                                i_doc_element_qualif => i_doc_element_qualif,
                                o_doc_macro          => o_doc_macro,
                                o_doc_macro_version  => o_doc_macro_version);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END save_macro;

    /*************************************************************************
    * Function used to return action list for a doc_area, doc_template,      *
    * institution and professional                                           *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @i_doc_area               Documentation Area identifier                *
    * @i_doc_template           Documentation Template identifier            *
    * @o_doc_macro_list         Actions list                                 *
    *                                                                        *
    * @return                   true or false on success or error            *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    FUNCTION get_template_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template IN doc_macro_version.id_doc_template%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_template_actions';
    BEGIN
        g_error := 'Call pk_doc_macro.get_templates_actions';
        pk_doc_macro.get_templates_actions(i_lang           => i_lang,
                                           i_prof           => i_prof,
                                           i_doc_area       => i_doc_area,
                                           i_doc_template   => i_doc_template,
                                           i_subject        => pk_doc_macro.g_action_template_subject,
                                           i_from_state     => pk_doc_macro.g_action_template_new_rec,
                                           o_doc_macro_list => o_actions);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_cursor_if_closed(i_cursor => o_actions);
            RETURN FALSE;
    END get_template_actions;

    /*************************************************************************
    * Function used to return software list shared for a doc_area,           *
    * doc_template, institution and professional                             *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @i_doc_area               Documentation Area identifier                *
    * @i_doc_template           Documentation Template identifier            *
    * @o_software_list          Software list                                *
    *                                                                        *
    * @return                   true or false on success or error            *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    FUNCTION get_shared_macro_software
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area      IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template  IN doc_macro_version.id_doc_template%TYPE,
        o_software_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_shared_macro_software';
    BEGIN
        g_error := 'Call pk_doc_macro.get_shared_macro_software';
        pk_doc_macro.get_shared_macro_software(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_doc_area      => i_doc_area,
                                               i_doc_template  => i_doc_template,
                                               o_software_list => o_software_list);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_cursor_if_closed(i_cursor => o_software_list);
            RETURN FALSE;
    END get_shared_macro_software;

    /*************************************************************************
    * Function used to return the values of a template used in a macro       *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_prof              Object (professional ID, institution ID,    *
    *                            software ID)                                *
    * @param i_doc_macro_version Doc macro version identifier                *
    *                                                                        *
    * @param o_macro_documentation Cursor with macro version documentation   *
    *                              values                                    *
    * @param o_element_domain      Cursor with elements domain               *
    *                                                                        *
    * @return                   true or false on success or error            *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/27                                   *
    *************************************************************************/
    FUNCTION get_macro_documentation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_macro_version IN doc_macro_version.id_doc_macro_version%TYPE,
        o_epis_document     OUT pk_types.cursor_type,
        o_element_domain    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_macro_documentation';
    BEGIN
        g_error := 'Call pk_doc_macro.get_macro_documentation';
        pk_doc_macro.get_macro_documentation(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_doc_macro_version   => i_doc_macro_version,
                                             o_macro_documentation => o_epis_document,
                                             o_element_domain      => o_element_domain);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_cursor_if_closed(i_cursor => o_epis_document);
            pk_types.open_cursor_if_closed(i_cursor => o_element_domain);
        
            RETURN FALSE;
    END get_macro_documentation;

    /*************************************************************************
    * Sets status for macro record (Active/Inactive/Cancelled)               *
    *                                                                        *
    * @param   i_lang           Professional preferred language              *
    * @param   i_prof           Professional identification and its context  *
    *                           (institution and software)                   *
    * @param   i_doc_macro      Doc_Macro ID                                 *
    * @param   i_flg_status     Doc macro status                             *
    *                           A - Active; I - Inactive; C - Canceled       *
    *                                                                        *
    * @param   o_error          Error information                            *
    *                                                                        *
    * @return  True or False on success or error                             *
    *                                                                        *
    * @author  GUSTAVO.SERRANO                                               *
    * @version 2.6.2                                                         *
    * @since   2012/03/09                                                    *
    *************************************************************************/
    FUNCTION set_macro_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_doc_macro  IN doc_macro.id_doc_macro%TYPE,
        i_flg_status IN doc_macro.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_macro_status';
    BEGIN
        g_error := 'Call pk_doc_macro.set_macro_status';
        pk_doc_macro.set_macro_status(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_doc_macro  => i_doc_macro,
                                      i_flg_status => i_flg_status);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN pk_doc_macro.e_ux_exception THEN
            DECLARE
                l_action_message sys_message.desc_message%TYPE;
                l_error_message  sys_message.desc_message%TYPE;
            BEGIN
                l_error_message  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DOC_MACRO_T001');
                l_action_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DOC_MACRO_M026');
            
                pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                    i_sqlcode     => NULL,
                                                    i_sqlerrm     => NULL,
                                                    i_message     => NULL,
                                                    i_owner       => g_package_owner,
                                                    i_package     => g_package_name,
                                                    i_function    => l_function_name,
                                                    i_action_type => 'U',
                                                    i_action_msg  => l_action_message,
                                                    i_msg_title   => l_error_message,
                                                    o_error       => o_error);
                ROLLBACK;
                RETURN TRUE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_macro_status;

    /*************************************************************************
    * Function used to return information for macro edition                 *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_prof              Object (professional ID, institution ID,    *
    *                            software ID)                                *
    * @param i_doc_macro         Doc macro identifier                        *
    *                                                                        *
    * @param o_macro_info          Cursor with macro information             *                 
    * @param o_macro_documentation Cursor with macro version documentation   *
    *                              values                                    *
    * @param o_element_domain      Cursor with elements domain               *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/09                                   *
    *************************************************************************/
    FUNCTION get_macro_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_doc_macro           IN doc_macro_version.id_doc_macro_version%TYPE,
        o_macro_info          OUT pk_types.cursor_type,
        o_macro_documentation OUT pk_types.cursor_type,
        o_element_domain      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_macro_info';
    BEGIN
        g_error := 'Call pk_doc_macro.get_macro_info';
        pk_alertlog.log_debug(text => g_error, object_name => l_function_name, sub_object_name => l_function_name);
        pk_doc_macro.get_macro_info(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_doc_macro           => i_doc_macro,
                                    o_macro_info          => o_macro_info,
                                    o_macro_documentation => o_macro_documentation,
                                    o_element_domain      => o_element_domain);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_cursor_if_closed(i_cursor => o_macro_info);
            pk_types.open_cursor_if_closed(i_cursor => o_macro_documentation);
            pk_types.open_cursor_if_closed(i_cursor => o_element_domain);
        
            RETURN FALSE;
    END get_macro_info;

    /*************************************************************************
    * Function used to return information for macro detail screen           *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_prof              Object (professional ID, institution ID,    *
    *                            software ID)                                *
    * @param i_doc_macro         Doc macro identifier                        *
    *                                                                        *
    * @param o_macro_detail       Cursor with macro information              *                 
    * @param o_doc_area_register  Cursor with the doc area info register     *
    * @param o_doc_area_val       Cursor with containing the completed info  *
    * @param o_template_layouts   Cursor containing the layout for each      *
    *                             template used                              *
    * @param o_doc_area_component Cursor containing the components for each  *
    *                             template used                              *
    * @param o_record_count       Indicates the number of records that match *
    *                             filters criteria                           *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/09                                   *
    *************************************************************************/
    FUNCTION get_macro_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_macro          IN doc_macro_version.id_doc_macro_version%TYPE,
        o_macro_detail       OUT pk_types.cursor_type,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_macro_detail';
    BEGIN
        g_error := 'Call pk_doc_macro.get_macro_detail';
        pk_doc_macro.get_macro_detail(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_doc_macro          => i_doc_macro,
                                      i_flg_hist           => pk_alert_constant.g_yes,
                                      o_macro_detail       => o_macro_detail,
                                      o_doc_area_register  => o_doc_area_register,
                                      o_doc_area_val       => o_doc_area_val,
                                      o_template_layouts   => o_template_layouts,
                                      o_doc_area_component => o_doc_area_component,
                                      o_record_count       => o_record_count,
                                      o_error              => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_touch_option.open_cur_doc_area_register(i_cursor => o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(i_cursor => o_doc_area_val);
        
            pk_types.open_cursor_if_closed(i_cursor => o_macro_detail);
            pk_types.open_cursor_if_closed(i_cursor => o_template_layouts);
            pk_types.open_cursor_if_closed(i_cursor => o_doc_area_component);
        
            RETURN FALSE;
    END get_macro_detail;

    /*************************************************************************
    * Function used to return information for macro detail screen            *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_doc_area         Doc macro identifier                         *
    * @param i_doc_template     Cursor with macro information                *                 
    * @param i_macro_name       Cursor with the doc area info register       *
    * @param o_doc_macro        Cursor with containing the completed info    *
    *                                                                        *
    * @return                   true or false on success or error            *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/04/03                                   *
    *************************************************************************/
    FUNCTION check_doc_macro_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE,
        i_macro_name   IN VARCHAR2,
        o_doc_macro    OUT doc_macro.id_doc_macro%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_doc_macro_name';
    BEGIN
        g_error := 'Call pk_doc_macro.check_doc_macro_name';
        pk_doc_macro.check_doc_macro_name(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_doc_area     => i_doc_area,
                                          i_doc_template => i_doc_template,
                                          i_macro_name   => i_macro_name,
                                          o_doc_macro    => o_doc_macro);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END check_doc_macro_name;

    /**
    * Checks if there are macros that its content has changed as consequence of a migration of template originally used.
    * These macros are marked with status "pending validation" so that the professional can validate the migrated content and change their status.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   o_info         Information about the existence of migrated macros
    * @param   o_error        Error information
    *
    * @return  true or false on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.2
    * @since   1/24/2013 12:14:00 PM
    */
    FUNCTION check_migrated_macro
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_migrated_macro';
    BEGIN
        g_error := 'Call pk_doc_macro.check_migrated_macro';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => k_function_name);
    
        pk_doc_macro.check_migrated_macro(i_lang => i_lang, i_prof => i_prof, o_info => o_info, o_error => o_error);
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
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END check_migrated_macro;

BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_doc_macro_ux;
/
