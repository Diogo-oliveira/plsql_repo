/*-- Last Change Revision: $Rev: 2027835 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_filters IS
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    PROCEDURE log_debug
    (
        i_sub_object_name IN VARCHAR2,
        i_text            IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => i_sub_object_name, text => i_text);
    END log_debug;

    PROCEDURE process_error
    (
        i_lang     IN NUMBER,
        i_function IN VARCHAR2,
        o_error    OUT t_error_out
    ) IS
    BEGIN

        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => SQLCODE,
                                          i_sqlerrm  => SQLERRM,
                                          i_message  => SQLERRM,
                                          i_owner    => g_owner,
                                          i_package  => g_package,
                                          i_function => i_function,
                                          o_error    => o_error);

    END process_error;
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
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
        err_executing_filter EXCEPTION;
        err_listing_filters  EXCEPTION;
        l_filter_name VARCHAR2(0200 CHAR);
        o_dropdown    pk_types.cursor_type;
        --o_lov_name           pk_types.cursor_type;
        l_id_custom_filter NUMBER;
        l_id_lov           NUMBER;
        l_lov_name         VARCHAR2(1000 CHAR);
        l_menu_path        table_varchar := table_varchar();
        l_text_search_id   NUMBER;
        l_page_size        NUMBER;
    
        PROCEDURE process_err(i_func_name IN VARCHAR2) IS
    BEGIN

            process_error(i_lang => i_lang, i_function => i_func_name, o_error => o_error);
            pk_types.open_cursor_if_closed(o_cursor);
            pk_types.open_cursor_if_closed(o_dropdown);
        
        END process_err;
    
    BEGIN

        l_filter_name := pk_core_filters.get_filter_name(i_list_class => i_list_class);
    
        l_bool := pk_filter_menu.get_default_filter(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_id_episode       => i_episode,
                                                     i_id_patient       => i_patient,
                                                     i_ux_list_class    => i_list_class,
                                                     o_id_custom_filter => l_id_custom_filter,
                                                     o_id_lov           => l_id_lov,
                                                     o_lov_name         => l_lov_name,
                                                     o_menu_path        => l_menu_path,
                                                     o_text_search_id   => l_text_search_id,
                                                     o_page_size        => l_page_size);
    
        /*
        l_bool := pk_core_filters.run_default_filter(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_episode            => i_episode,
                                       i_patient            => i_patient,
                                       i_context            => i_context,
                                       i_context_keys       => i_context_keys,
                                       i_list_class         => i_list_class,
                                       i_first_element      => i_first_element,
                                       i_order_aliases      => i_order_aliases,
                                       i_order_directions   => i_order_directions,
                                           i_page_size          => i_page_size,
                                                     i_tbl_field          => i_tbl_field,
                                                     i_tbl_value          => i_tbl_value,
                                       o_filter             => o_filter,
                                       o_custom_filter      => o_custom_filter,
                                           o_flg_search_needed  => o_flg_search_needed,
                                       o_text_search_id     => o_text_search_id,
                                           o_text_search_desc   => o_text_search_desc,
                                           o_id_cstm_executed   => o_id_cstm_executed,
                                      o_custom_filter_desc => o_custom_filter_desc,
                                           o_page_size          => o_page_size,
                                      o_num_results        => o_num_results,
                                                     o_error              => o_error,
                                      o_cursor             => o_cursor);
         */
        if not l_bool then
           return false;
        end if;
         
        l_bool := pk_core_filters.run_filter_list(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_episode          => i_episode,
                                                  i_patient          => i_patient,
                                                  i_context          => i_context,
                                                  i_context_keys     => i_context_keys,
                                                  i_filter           => l_filter_name,
                                                  i_custom_filter    => l_id_custom_filter,
                                                  i_first_element    => i_first_element,
                                                  i_order_aliases    => i_order_aliases,
                                                  i_order_directions => i_order_directions,
                                                  i_text_search_id   => l_text_search_id,
                                                  i_text_search_val  => null,
                                                  i_page_size        => nvl( l_page_size, i_page_size),
                                                  i_tbl_field        => i_tbl_field,
                                                  i_tbl_value        => i_tbl_value,
                                                  --o_page_size          => o_page_size,
                                                  o_flg_search_needed  => o_flg_search_needed,
                                                  o_text_search_desc   => o_text_search_desc,
                                                  o_id_cstm_executed   => o_id_cstm_executed,
                                                  o_custom_filter_desc => o_custom_filter_desc,
                                                  o_num_results        => o_num_results,
                                                  o_error              => o_error,
                                                  o_cursor             => o_cursor);
    
        IF NOT l_bool
        THEN
            l_filter_name := 'RUN_DEFAULT_FILTER';
            RAISE err_executing_filter;
        END IF;
    
        o_filter := l_filter_name;
        o_text_search_id := l_text_search_id;
        o_page_size := nvl( l_page_size, i_page_size);
        o_menu_path := pk_filter_menu.get_menu_path(i_prof          => i_prof,
                                                    i_tbl_menu_path => l_menu_path,
                                                i_filter_name => o_filter,
                                                    i_cst           => l_id_custom_filter,
                                                    i_cst_exe       => o_id_cstm_executed);
    
    
        RETURN l_bool;
    
    EXCEPTION
        WHEN err_executing_filter
             OR err_listing_filters THEN
            process_err(i_func_name => l_filter_name);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            process_err(i_func_name => 'RUN_DEFAULT_FILTER');
            RETURN FALSE;
    END run_default_filter;

    /**
    * Returns the list of filters available for a given screen
    *
    * @return     True if succeded or false otherwise
    * @author     Fábio Oliveira
    * @version    2.6.1
    * @since      14-Mar-2011
    */
    FUNCTION get_filter_dropdown
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_filter   IN custom_filter.filter_name%TYPE,
        i_episode  IN NUMBER,
        i_patient  IN NUMBER,
        i_tbl_par_name  IN table_varchar,
        i_tbl_par_value IN table_varchar,
        o_dropdown OUT pk_types.cursor_type,
        o_lov_name OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_filter_menu.get_filter_list(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_filter_name => i_filter,
                                             i_id_episode  => i_episode,
                                             i_id_patient  => i_patient,
                                             i_tbl_par_name  => i_tbl_par_name,
                                             i_tbl_par_value => i_tbl_par_value,
                                             o_list        => o_dropdown,
                                             o_lov_data    => o_lov_name,
                                             o_error       => o_error);
    
    END get_filter_dropdown;

    FUNCTION get_filter_dropdown
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_filter   IN custom_filter.filter_name%TYPE,
        o_dropdown OUT pk_types.cursor_type,
        o_lov_name OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_bool BOOLEAN;
    BEGIN

        RETURN get_filter_dropdown(i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   i_filter   => i_filter,
                                   i_episode  => NULL,
                                   i_patient  => NULL,
                                   i_tbl_par_name  => table_varchar(),
                                   i_tbl_par_value => table_varchar(),
                                   o_dropdown => o_dropdown,
                                   o_lov_name => o_lov_name,
                                   o_error    => o_error);
    
    END get_filter_dropdown;

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
        i_prof               IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_audit_area IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN TRUE;
    END audit_copy;

    FUNCTION run_filter_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_context            IN table_varchar,
        i_context_keys       IN table_varchar DEFAULT NULL,
        i_filter        IN custom_filter.filter_name%TYPE,
        i_custom_filter      IN custom_filter.id_custom_filter%TYPE,
        i_first_element      IN NUMBER,
        i_order_aliases      IN table_varchar,
        i_order_directions   IN table_varchar,
        i_text_search_id     IN custom_filter_field.id_filter_field%TYPE DEFAULT NULL,
        i_text_search_val    IN VARCHAR2 DEFAULT NULL,
        i_page_size     IN custom_filter.page_size%TYPE,
        i_tbl_field          IN table_table_varchar,
        i_tbl_value          IN table_table_varchar,
        i_menu_path          IN table_varchar,
        o_page_size          OUT NUMBER,
        o_flg_search_needed  OUT VARCHAR2,
        o_id_cstm_executed   OUT NUMBER,
        o_custom_filter_desc OUT custom_filter.custom_filter_name%TYPE,
        o_text_search_desc   OUT VARCHAR2,
        o_num_results        OUT NUMBER,
        o_menu_path          OUT table_varchar,
        o_cursor             OUT pk_types.cursor_type,
            o_error         OUT t_error_out
        ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
        l_page_size NUMBER := i_page_size;
        BEGIN
    
        o_page_size := l_page_size;
			l_bool := pk_core_filters.run_filter_list(i_lang => i_lang,
                                        i_prof          => i_prof,
                                        i_episode            => i_episode,
                                        i_patient            => i_patient,
                                        i_context            => i_context,
                                        i_context_keys       => i_context_keys,
                                        i_filter             => i_filter,
                                                            i_custom_filter => i_custom_filter,
                                        i_first_element      => i_first_element,
                                        i_order_aliases      => i_order_aliases,
                                        i_order_directions   => i_order_directions,
                                        i_text_search_id     => i_text_search_id,
                                        i_text_search_val    => i_text_search_val,
                                        i_page_size          => i_page_size,
                                                  i_tbl_field          => i_tbl_field,
                                                  i_tbl_value          => i_tbl_value,
                                                       --o_page_size          => o_page_size,
                                        o_flg_search_needed  => o_flg_search_needed,
                                        o_text_search_desc   => o_text_search_desc,
                                        o_id_cstm_executed   => o_id_cstm_executed,
                                        o_custom_filter_desc => o_custom_filter_desc,
                                        o_num_results        => o_num_results,
                                                  o_error              => o_error,
                                        o_cursor             => o_cursor);

        o_menu_path := pk_filter_menu.get_menu_path(i_prof          => i_prof,
                                                    i_tbl_menu_path => i_menu_path,
                                                    i_filter_name   => i_filter,
                                                    i_cst           => i_custom_filter,
                                                    i_cst_exe       => o_id_cstm_executed);
    
        RETURN l_bool;
        EXCEPTION
            WHEN OTHERS THEN
            process_error(i_lang => i_lang, i_function => 'RUN_FILTER_LIST', o_error => o_error);
            pk_types.open_my_cursor(o_cursor);

                RETURN FALSE;
    END run_filter_list;

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
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
        --l_filter_name VARCHAR2(0200 CHAR);
        l_page_size NUMBER := i_page_size;
    BEGIN
    
        o_page_size := l_page_size;
        l_bool := pk_core_filters.run_filter_search(i_lang               => i_lang,
                               i_prof             => i_prof,
                               i_episode          => i_episode,
                               i_patient          => i_patient,
                               i_context          => i_context,
                               i_context_keys     => i_context_keys,
                               i_filter           => i_filter,
                               i_custom_filter    => i_custom_filter,
                               i_first_element    => i_first_element,
                               i_order_aliases    => i_order_aliases,
                               i_order_directions => i_order_directions,
                               i_text_search_id   => i_text_search_id,
                               i_text_search_val  => i_text_search_val,
                               i_page_size          => i_page_size,
                               i_tbl_field          => i_tbl_field,
                               i_tbl_value          => i_tbl_value,
                                                         --o_page_size          => o_page_size,
                               o_flg_search_needed  => o_flg_search_needed,
                               o_text_search_desc   => o_text_search_desc,
                               o_id_cstm_executed   => o_id_cstm_executed,
                               o_custom_filter_desc => o_custom_filter_desc,
                               o_num_results      => o_num_results,
                               o_error              => o_error,
                               o_cursor             => o_cursor);

        o_menu_path := pk_filter_menu.get_menu_path(i_prof          => i_prof,
                                                    i_tbl_menu_path => i_menu_path,
                                                    i_filter_name   => i_filter,
                                                    i_cst           => i_custom_filter,
                                                    i_cst_exe       => o_id_cstm_executed);
    
        RETURN l_bool;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang => i_lang, i_function => 'RUN_FILTER_SEARCH', o_error => o_error);
            pk_types.open_my_cursor(o_cursor);

            RETURN FALSE;
    END run_filter_search;

    FUNCTION run_filter_page
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
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
        --l_filter_name VARCHAR2(0200 CHAR);
        l_page_size NUMBER := i_page_size;
    BEGIN
    
        o_page_size := l_page_size;
        l_bool := pk_core_filters.run_filter_page(i_lang               => i_lang,
                                 i_prof             => i_prof,
                                 i_episode          => i_episode,
                                 i_patient          => i_patient,
                                 i_context          => i_context,
                                 i_context_keys     => i_context_keys,
                                 i_filter           => i_filter,
                                 i_custom_filter    => i_custom_filter,
                                 i_first_element    => i_first_element,
                                 i_order_aliases    => i_order_aliases,
                                 i_order_directions => i_order_directions,
                                 i_text_search_id   => i_text_search_id,
                                 i_text_search_val  => i_text_search_val,
                                 i_page_size        => i_page_size,
                                                  i_tbl_field          => i_tbl_field,
                                                  i_tbl_value          => i_tbl_value,
                                                       --o_page_size          => o_page_size,
                                        o_flg_search_needed  => o_flg_search_needed,
                                        o_text_search_desc   => o_text_search_desc,
                                        o_id_cstm_executed   => o_id_cstm_executed,
                                        o_custom_filter_desc => o_custom_filter_desc,
                                 o_num_results      => o_num_results,
                                                  o_error              => o_error,
                                 o_cursor           => o_cursor);

        o_menu_path := pk_filter_menu.get_menu_path(i_prof          => i_prof,
                                                    i_tbl_menu_path => i_menu_path,
                                                    i_filter_name   => i_filter,
                                                    i_cst           => i_custom_filter,
                                                    i_cst_exe       => o_id_cstm_executed);
    
        RETURN l_bool;
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang => i_lang, i_function => 'RUN_FILTER_PAGE', o_error => o_error);
            pk_types.open_my_cursor(o_cursor);

            RETURN FALSE;
    END run_filter_page;
	
    -- function that returns seach criteria available
    FUNCTION get_filter_criteria
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_filter_name IN VARCHAR2,
        o_sql         OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_core_filters.get_filter_criteria(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_filter_name  => i_filter_name,
                                                   i_only_default => 'N',
                                                   o_sql          => o_sql,
                                                   o_error        => o_error);
    
    END get_filter_criteria;
	
BEGIN
    pk_alertlog.who_am_i(g_owner, g_package);
END pk_ux_filters;
/
