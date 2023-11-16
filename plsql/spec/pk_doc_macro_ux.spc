/*-- Last Change Revision: $Rev: 2028623 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_doc_macro_ux IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
END pk_doc_macro_ux;
/
