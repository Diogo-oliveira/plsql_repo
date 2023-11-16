/*-- Last Change Revision: $Rev: 2029031 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ux_filters IS

    /**
    * Returns the list of filters available for a given screen
    *
    * @return     True if succeded or false otherwise
    * @author     Fábio Oliveira
    * @version    2.6.1
    * @since      14-Mar-2011
    */
    /*
    FUNCTION get_filter_dropdown
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_filter        IN custom_filter.filter_name%TYPE,
        o_dropdown OUT pk_types.cursor_type,
        o_lov_name OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    */

    /**
    * This function is used only for audit purpose. The function does nothing. Do not change.
    *
    * @return     True
    * @author     Pedro Pinheiro
    * @version    2.6.4.0.3
    * @since      26-May-2014
    */
    FUNCTION audit_copy
    (
        i_prof          IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_audit_area IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION run_default_filter
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_context            IN table_varchar,
        i_context_keys       IN table_varchar DEFAULT NULL,
        i_list_class         IN ux_list_class.class_name%TYPE,
        i_first_element      IN NUMBER,
        i_order_aliases      IN table_varchar,
        i_order_directions   IN table_varchar,
        i_page_size          IN custom_filter.page_size%TYPE,
        i_tbl_field          IN table_table_varchar,
        i_tbl_value          IN table_table_varchar,
        o_filter             OUT custom_filter.filter_name%TYPE,
        o_custom_filter      OUT custom_filter.id_custom_filter%TYPE,
        o_flg_search_needed  OUT VARCHAR2,
        o_text_search_id     OUT custom_filter_field.id_filter_field%TYPE,
        o_text_search_desc   OUT VARCHAR2,
        o_id_cstm_executed   OUT custom_filter.id_custom_filter%TYPE,
        o_custom_filter_desc OUT custom_filter.custom_filter_name%TYPE,
        o_page_size          OUT custom_filter.page_size%TYPE,
        o_num_results        OUT NUMBER,
        o_menu_path          OUT table_varchar,
        o_cursor             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION run_filter_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_context          IN table_varchar,
        i_context_keys       IN table_varchar DEFAULT NULL,
        i_filter           IN custom_filter.filter_name%TYPE,
        i_custom_filter    IN custom_filter.id_custom_filter%TYPE,
        i_first_element    IN NUMBER,
        i_order_aliases    IN table_varchar,
        i_order_directions IN table_varchar,
        i_text_search_id   IN custom_filter_field.id_filter_field%TYPE DEFAULT NULL,
        i_text_search_val  IN VARCHAR2 DEFAULT NULL,
        i_page_size          IN custom_filter.page_size%TYPE,
        i_tbl_field          IN table_table_varchar,
        i_tbl_value          IN table_table_varchar,
        i_menu_path          IN table_varchar,
        o_page_size          OUT NUMBER,
        o_flg_search_needed  OUT VARCHAR2,
        o_id_cstm_executed   OUT NUMBER,
        o_custom_filter_desc OUT custom_filter.custom_filter_name%TYPE,
        o_text_search_desc   OUT VARCHAR2,
        o_num_results      OUT NUMBER,
        o_menu_path          OUT table_varchar,
        o_cursor           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION run_filter_search
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_context          IN table_varchar,
        i_context_keys       IN table_varchar DEFAULT NULL,
        i_filter           IN custom_filter.filter_name%TYPE,
        i_custom_filter    IN custom_filter.id_custom_filter%TYPE,
        i_first_element    IN NUMBER,
        i_order_aliases    IN table_varchar,
        i_order_directions IN table_varchar,
        i_text_search_id   IN custom_filter_field.id_filter_field%TYPE DEFAULT NULL,
        i_text_search_val  IN VARCHAR2 DEFAULT NULL,
        i_page_size        IN custom_filter.page_size%TYPE,
        i_tbl_field          IN table_table_varchar,
        i_tbl_value          IN table_table_varchar,
        i_menu_path          IN table_varchar,
        o_page_size          OUT NUMBER,
        o_flg_search_needed  OUT VARCHAR2,
        o_id_cstm_executed   OUT NUMBER,
        o_custom_filter_desc OUT custom_filter.custom_filter_name%TYPE,
        o_text_search_desc   OUT VARCHAR2,
        o_num_results      OUT NUMBER,
        o_menu_path          OUT table_varchar,
        o_cursor           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;


    FUNCTION run_filter_page
        (
            i_lang             IN language.id_language%TYPE,
            i_prof             IN profissional,
            i_episode          IN episode.id_episode%TYPE,
            i_patient          IN patient.id_patient%TYPE,
            i_context          IN table_varchar,
            i_context_keys     IN table_varchar DEFAULT NULL,
            i_filter           IN custom_filter.filter_name%TYPE,
            i_custom_filter    IN custom_filter.id_custom_filter%TYPE,
            i_first_element    IN NUMBER,
            i_order_aliases    IN table_varchar,
            i_order_directions IN table_varchar,
            i_text_search_id   IN custom_filter_field.id_filter_field%TYPE DEFAULT NULL,
            i_text_search_val  IN VARCHAR2 DEFAULT NULL,
            i_page_size        IN custom_filter.page_size%TYPE,
        i_tbl_field          IN table_table_varchar,
        i_tbl_value          IN table_table_varchar,
        i_menu_path          IN table_varchar,
        o_page_size          OUT NUMBER,
        o_flg_search_needed  OUT VARCHAR2,
        o_id_cstm_executed   OUT NUMBER,
        o_custom_filter_desc OUT custom_filter.custom_filter_name%TYPE,
        o_text_search_desc   OUT VARCHAR2,
            o_num_results      OUT NUMBER,
        o_menu_path          OUT table_varchar,
        o_cursor             OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_filter_criteria
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_filter_name IN VARCHAR2,
        o_sql         OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_filter_dropdown
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_filter   IN custom_filter.filter_name%TYPE,
		i_episode  in number,
		i_patient  in number,
        i_tbl_par_name  IN table_varchar,
        i_tbl_par_value IN table_varchar,
        o_dropdown OUT pk_types.cursor_type,
        o_lov_name OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ux_filters;
/
