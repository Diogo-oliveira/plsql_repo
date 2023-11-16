/*-- Last Change Revision: $Rev: 1849926 $*/
/*-- Last Change by: $Author: vitor.sa $*/
/*-- Date of last change: $Date: 2018-06-29 09:27:06 +0100 (sex, 29 jun 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_touch_option IS

    /**######################################################
      GLOBALS
    ######################################################**/
    SUBTYPE t_rec_last_elem_val IS pk_touch_option.t_rec_last_elem_val;
    SUBTYPE t_coll_last_elem_val IS pk_touch_option.t_coll_last_elem_val;

    g_exception EXCEPTION;

    /********************************************************************************************
    * Returns the value of specific elements from last documentation for an area, episode and template
    *
    * @param i_lang                Language ID                                                                                              
    * @param i_prof                Professional, software and institution ids                                                                                                                                          
    * @param i_episode             Episode ID 
    * @param i_doc_area            Area ID where check if registers were done
    * @param i_doc_template        (Optional) Template ID. Null = All templates
    * @param i_table_element_keys  Array of elements keys to retrieve their values
    * @param i_key_type            Type of key (ID, Internal Name, ID Content, etc)
    * @param o_last_epis_doc       Last documentation ID 
    * @param o_last_date_epis_doc  Date of last epis documentation
    * @param o_element_values      Element values
    * @param o_error               Error info
    *                        
    * @return                      true or false on success or error
    *
    * @value i_key_type  {*} 'K' Element's key (id_doc_element) {*} 'N' Element's internal name 
    *
    * @autor                       Ariel Machado
    * @version                     1.0
    * @since                       2009/03/19
    **********************************************************************************************/
    FUNCTION intf_last_doc_area_elem_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        i_table_element_keys IN table_varchar,
        i_key_type           IN VARCHAR2,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_element_values     OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    -- ****************************
    -- map values and set_Template
    -- ****************************
    FUNCTION map_n_set_template
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        --i_id_documentation      IN table_number,
        i_doc_element_name IN table_varchar,
        i_tbl_doc_criteria IN table_number,
        i_value            IN table_varchar,
        i_notes            IN epis_documentation.notes%TYPE,
		i_dt_creation      in varchar2,
        i_id_doc_element_qualif IN table_table_number,
        o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    -- ****************************
    -- map values and set_Template full
    -- ****************************
    FUNCTION map_n_set_template_vital_sign
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_element_name      IN table_varchar,
        i_tbl_doc_criteria      IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_dt_creation           IN VARCHAR2,
        i_id_doc_element_qualif IN table_table_number DEFAULT NULL,
        i_id_vital_sign         IN table_table_number DEFAULT NULL,
        i_vs_value_list         IN table_table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_uom_list           IN table_table_number DEFAULT NULL,
        i_vs_scales_list        IN table_table_number DEFAULT NULL,
        i_vs_date_list          IN table_table_varchar DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    -- Cancelamento de templates
    FUNCTION cancel_template
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_epis_documentation IN NUMBER,
        i_cancel_reason      IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel       IN VARCHAR2,
		i_dt_cancel          in varchar2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_values                IN table_number,
        i_flg_score_type        IN VARCHAR2,
        i_nr_answered_questions IN PLS_INTEGER,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    
    FUNCTION get_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_values                IN table_number,
        i_flg_score_type        IN VARCHAR2,
        i_nr_answered_questions IN PLS_INTEGER,
        o_score_value           OUT VARCHAR2,
        o_id_scales_formula     OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    
    PROCEDURE set_vs_arrays
    (
        i_id_vital_sign     IN table_table_number,
        i_vs_value_list     IN table_table_number,
        i_vs_save_mode_list IN table_table_varchar,
        i_vs_uom_list       IN table_table_number,
        i_vs_scales_list    IN table_table_number,
        i_vs_date_list      IN table_table_varchar,
        o_id_vital_sign     OUT table_table_number,
        o_vs_value_list     OUT table_table_number,
        o_vs_save_mode_list OUT table_table_varchar,
        o_vs_uom_list       OUT table_table_number,
        o_vs_scales_list    OUT table_table_number,
        o_vs_date_list      OUT table_table_varchar
    );

    --Global error message
    g_error VARCHAR2(32767);
    --Package name
    g_package_name VARCHAR2(32);
    --Package owner
    g_package_owner VARCHAR2(32);
END pk_api_touch_option;
/
