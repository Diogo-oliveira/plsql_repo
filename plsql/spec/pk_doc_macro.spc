/*-- Last Change Revision: $Rev: 2028621 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_doc_macro IS

    -- Exceptions

    -- exception for UX
    e_ux_exception EXCEPTION;

    -- Public type declarations    
    TYPE t_rec_macro_info IS RECORD(
        id_doc_macro         doc_macro.id_doc_macro%TYPE,
        id_doc_macro_version doc_macro_version.id_doc_macro_version%TYPE,
        doc_macro_name       pk_translation.t_desc_translation,
        flg_status           doc_macro.flg_status%TYPE);
    TYPE t_coll_rec_macro_info IS TABLE OF t_rec_macro_info;
    TYPE t_cur_macro_info IS REF CURSOR RETURN t_rec_macro_info;

    -- Public constant declarations
    g_flg_edition_type_new       CONSTANT doc_macro_version.flg_edition_type%TYPE := 'N';
    g_flg_edition_type_edit      CONSTANT doc_macro_version.flg_edition_type%TYPE := 'E';
    g_flg_edition_type_nochanges CONSTANT epis_documentation.flg_edition_type%TYPE := 'O';

    g_elem_flg_type_comp_numeric   CONSTANT doc_element.flg_type%TYPE := 'CN'; --Element type: compound element for number
    g_elem_flg_type_comp_ref_value CONSTANT doc_element.flg_type%TYPE := 'CR'; --Element type: compound element for number    
    g_elem_flg_type_comp_date      CONSTANT doc_element.flg_type%TYPE := 'CD'; --Element type: compound element for date

    g_dcmv_flg_status_outd   CONSTANT doc_macro_version.flg_status%TYPE := 'O';
    g_dcmv_flg_status_active CONSTANT doc_macro_version.flg_status%TYPE := 'A';

    g_dcm_flg_status_sysdomain CONSTANT sys_domain.code_domain%TYPE := 'DOC_MACRO.FLG_STATUS';
    g_dcm_flg_share_sysdomain  CONSTANT sys_domain.code_domain%TYPE := 'DOC_MACRO.FLG_SHARE';

    g_dcm_flg_status_active   CONSTANT doc_macro.flg_status%TYPE := 'A';
    g_dcm_flg_status_inactive CONSTANT doc_macro.flg_status%TYPE := 'I';
    g_dcm_flg_status_canceled CONSTANT doc_macro.flg_status%TYPE := 'C';
    g_dcm_flg_status_disabled CONSTANT doc_macro.flg_status%TYPE := 'D';
    g_dcm_flg_status_pending  CONSTANT doc_macro.flg_status%TYPE := 'P';
    --    g_dcm_flg_status_outdated CONSTANT doc_macro.flg_status%TYPE := 'O';

    g_dcms_flg_status_active   CONSTANT doc_macro_soft.flg_status%TYPE := 'A';
    g_dcms_flg_status_inactive CONSTANT doc_macro_soft.flg_status%TYPE := 'I';
    g_dcms_flg_status_canceled CONSTANT doc_macro_soft.flg_status%TYPE := 'C';
    g_dcms_flg_status_disabled CONSTANT doc_macro_soft.flg_status%TYPE := 'D';
    --    g_dcms_flg_status_outdated CONSTANT doc_macro_soft.flg_status%TYPE := 'O';

    g_dcmp_flg_status_active   CONSTANT doc_macro_prof.flg_status%TYPE := 'A';
    g_dcmp_flg_status_inactive CONSTANT doc_macro_prof.flg_status%TYPE := 'I';
    g_dcmp_flg_status_canceled CONSTANT doc_macro_prof.flg_status%TYPE := 'C';
    g_dcmp_flg_status_disabled CONSTANT doc_macro_prof.flg_status%TYPE := 'D';
    --    g_dcmp_flg_status_outdated CONSTANT doc_macro_prof.flg_status%TYPE := 'O';

    g_action_template_subject CONSTANT action.subject%TYPE := 'DOC_MACRO_TEMPLATE';
    g_action_template_new_rec CONSTANT action.from_state%TYPE := 'N';
    g_action_template_apply   CONSTANT action.to_state%TYPE := 'A';

    g_action_apply_name CONSTANT action.internal_name%TYPE := 'MACRO_VERSION';

    g_doc_macro_module CONSTANT VARCHAR2(30) := 'DOC_MACRO';

    /*************************************************************************
    * Procedure used to create \ edit a template macro                       *
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
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/01/19                                   *
    *************************************************************************/
    PROCEDURE save_macro
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
        o_doc_macro_version  OUT doc_macro_version.id_doc_macro_version%TYPE
    );

    /*************************************************************************
    * Procedure used to return action list for a doc_area, doc_template,     *
    * institution and professional                                           *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @i_doc_area               Documentation Area identifier                *
    * @i_doc_template           Documentation Template identifier            *
    * @i_subject                Action subject                               *
    * @i_from_state             Action initial state                         *
    * @o_doc_macro_list         Actions list                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    PROCEDURE get_templates_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template   IN doc_macro_version.id_doc_template%TYPE,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        o_doc_macro_list OUT pk_types.cursor_type
    );

    /*************************************************************************
    * Procedure used to return software list shared for a doc_area,          *
    * doc_template, institution and professional                             *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @i_doc_area               Documentation Area identifier                *
    * @i_doc_template           Documentation Template identifier            *
    * @o_software_list          Software list                                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    PROCEDURE get_shared_macro_software
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area      IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template  IN doc_macro_version.id_doc_template%TYPE,
        o_software_list OUT pk_types.cursor_type
    );

    /*************************************************************************
    * Procedure used to return the values of a template used in a macro      *
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
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/27                                   *
    *************************************************************************/
    PROCEDURE get_macro_documentation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_doc_macro_version   IN doc_macro_version.id_doc_macro_version%TYPE,
        o_macro_documentation OUT pk_types.cursor_type,
        o_element_domain      OUT pk_types.cursor_type
    );

    /*************************************************************************
    * Procedure that resolves bind variables required for the filter         *
    * TOTMacroDocumentation                                                  *
    *                                                                        *
    * @param i_context_ids  Static contexts (i_prof, i_lang, i_episode,...)  *
    * @param i_context_vals Custom contexts, sent from the user interface    *
    * @param i_name         Name of the bind variable to get                 *
    * @param  o_vc2         Varchar2 value returned by the procedure         *
    * @param  o_num         Numeric value returned by the procedure          *
    * @param  o_id          NUMBER(24) value returned by the procedure       *
    * @param  o_tstz        Timestamp value returned by the procedure        *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  2.6.2.1                                      *
    * @since                    2012/03/08                                   *
    *************************************************************************/
    PROCEDURE init_fltr_params_doc_macro
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

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
    * @catches                                                               *
    * @throws                                                                *
    *                                                                        *
    * @author  GUSTAVO.SERRANO                                               *
    * @version 2.6.2                                                         *
    * @since   2012/03/09                                                    *
    *************************************************************************/
    PROCEDURE set_macro_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_doc_macro  IN doc_macro.id_doc_macro%TYPE,
        i_flg_status IN doc_macro.flg_status%TYPE
    );

    /*************************************************************************
    * Procedure used to return information for macro edition                 *
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
    PROCEDURE get_macro_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_doc_macro           IN doc_macro_version.id_doc_macro_version%TYPE,
        o_macro_info          OUT pk_types.cursor_type,
        o_macro_documentation OUT pk_types.cursor_type,
        o_element_domain      OUT pk_types.cursor_type
    );

    /*************************************************************************
    * Function used to get a full phrase associated to an element quantified *
    * based on pk_touch_option.get_epis_doc_quantification                   *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_doc_macro_version_det  Doc macro version detail identifier    *
    *                                                                        *
    * @return Full phrase associated with the element quantified             *
    *         (example: "Mild pain")                                         *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/13                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_quantification
    (
        i_lang                  IN language.id_language%TYPE,
        i_doc_macro_version_det IN doc_macro_version_det.id_doc_macro_version_det%TYPE
    ) RETURN VARCHAR2;

    /*************************************************************************
    * Function used to get a concatenated list of qualifications associated  *
    * with an element in parentheses.                                        *
    * based on pk_touch_option.get_epis_doc_qualification                    *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_doc_macro_version_det  Doc macro version detail identifier    *
    *                                                                        *
    * @return String with concatenated list of qualifications                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/13                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_qualification
    (
        i_lang                  IN language.id_language%TYPE,
        i_doc_macro_version_det IN doc_macro_version_det.id_doc_macro_version_det%TYPE
    ) RETURN VARCHAR2;

    /*************************************************************************
    * Function used to get the quantifier description associated to an       *
    * element quantified                                                     *
    *                                                                        *
    * This function is used for compatibility purposes to deal with old      *
    * descriptions for element's quantifier in templates.                    *
    * In new template's elements that make use of quantifiers this function  *
    * should return null values, and the new function                        *
    * get_epis_doc_quantification() return the full description for an       *
    * element quantified.                                                    *  
    * based on pk_touch_option.get_epis_doc_quantifier                       *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_doc_macro_version_det  Doc macro version detail identifier    *
    *                                                                        *
    * @return String with description associated with the quantifier         *
    *         (example: "mild")                                              *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/13                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_quantifier
    (
        i_lang                  IN language.id_language%TYPE,
        i_doc_macro_version_det IN doc_macro_version_det.id_doc_macro_version_det%TYPE
    ) RETURN VARCHAR2;

    /*************************************************************************
    * Procedure used to return information for macro detail screen           *
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
    PROCEDURE get_macro_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_macro          IN doc_macro_version.id_doc_macro_version%TYPE,
        i_flg_hist           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_macro_detail       OUT pk_types.cursor_type,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    );

    /*************************************************************************
    * Procedure to be used as an helper to validate permissions for a list   *
    * of macros based on his dependencies (such as software association      *
    * with professional, software association with doc_area and doc_template)*
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_tbl_doc_macro    List of doc macro identifiers (in case of    *
    *                           null or empty all macros for the user and    *
    *                           institution will be validated                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/14                                   *
    *************************************************************************/
    PROCEDURE update_dm_dependencies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_doc_macro IN table_number DEFAULT NULL
    );

    /*************************************************************************
    * Converts a cursor into a table_varchar                                  *
    *                                                                        *
    * @param p_cursor           Preferred language ID for this professional  *
    *                                                                        *
    * @return                   table_number                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  2.6.2.1                                      *
    * @since                    23/03/2012                                   *
    *************************************************************************/
    FUNCTION cursor2tbl_varchar(p_cursor IN SYS_REFCURSOR) RETURN table_varchar;

    /*************************************************************************
    * Fetches the id_institution used to create a doc_macro_version          *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    *                                                                        *
    * @return                   doc_macro.id_institution%TYPE                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  2.6.2.1                                      *
    * @since                    27/03/2012                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_version_instit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_macro_version IN doc_macro_version.id_doc_macro_version%TYPE
    ) RETURN doc_macro.id_institution%TYPE;

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
    PROCEDURE get_doc_products
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_products OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    );

    /********************************************************************************************
     * Get list of areas with templates for a specified product.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_product                Id of the product to get areas
     * @param o_doc_areas              List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    PROCEDURE get_doc_areas
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_doc_product IN software.id_software%TYPE,
        o_doc_areas   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    );

    /********************************************************************************************
     * Get list of templates for a specified product and area.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_product                Id of the product to get areas
     * @param i_area                   Id of the area to get templates
     * @param o_doc_templates          List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    PROCEDURE get_doc_templates
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_product   IN software.id_software%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_doc_templates OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    );

    /*************************************************************************
    * Procedure used to return information for macro detail screen           *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_doc_area         Doc macro identifier                         *
    * @param i_doc_template     Cursor with macro information                *                 
    * @param i_macro_name       Cursor with the doc area info register       *
    * @param o_doc_macro        Cursor with containing the completed info    *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/04/03                                   *
    *************************************************************************/
    PROCEDURE check_doc_macro_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE,
        i_macro_name   IN VARCHAR2,
        o_doc_macro    OUT doc_macro.id_doc_macro%TYPE
    );

    /*************************************************************************
    * Procedure used to return macros list                                   *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    PROCEDURE get_doc_macros_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template   IN doc_macro_version.id_doc_template%TYPE,
        o_doc_macro_list OUT t_cur_macro_info
    );

    /**
    *  Migration of a macro to use another template that replaces the one it was originally used.
    *
    * @param    i_lang         Language 
    * @param    i_doc_macro    Macro ID to migrate
    * @param    i_to_template  Template ID which that will be used for the migration of macro
    * @param    o_error        Error information
    *
    * @return  True or False on sucess or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.3
    * @since   1/15/2013 3:49:17 PM
    */
    FUNCTION set_migrate_macro
    (
        i_lang        IN language.id_language%TYPE,
        i_doc_macro   IN doc_macro.id_doc_macro%TYPE,
        i_to_template IN doc_template.id_doc_template%TYPE,
        o_error       OUT t_error_out
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
    * @author  ARIEL.MACHADO
    * @version 2.6.3.2
    * @since   1/24/2013 12:14:00 PM
    */
    PROCEDURE check_migrated_macro
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    );
END pk_doc_macro;
/
