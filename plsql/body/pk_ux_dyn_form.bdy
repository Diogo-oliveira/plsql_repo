/*-- Last Change Revision: $Rev: 2011154 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-03-18 15:51:08 +0000 (sex, 18 mar 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_dyn_form AS

    --k_pck_owner CONSTANT VARCHAR2(0030 CHAR) := 'ALERT';
    k_pck_name CONSTANT VARCHAR2(0030 CHAR) := pk_alertlog.who_am_i();

    -- *****************************************
    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar,
        o_result        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    BEGIN
    
        l_return := pk_dyn_form.get_multichoice(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_flg_type      => i_flg_type,
                                                i_internal_name => i_internal_name,
                                                o_result        => o_result,
                                                o_error         => o_error);
        RETURN l_return;
    
    END get_multichoice;

    -- new 
    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT pk_types.cursor_type,
        o_ds_target   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    BEGIN
    
        l_return := pk_dyn_form.get_full_items_by_screen(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_patient     => i_patient,
                                                         i_episode     => i_episode,
                                                         i_screen_name => i_screen_name,
                                                         i_action      => i_action,
                                                         o_components  => o_components,
                                                         o_ds_target   => o_ds_target,
                                                         o_error       => o_error);
    
        RETURN l_return;
    
    END get_full_items_by_screen;

    -- new 
    FUNCTION get_full_items_by_name
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_patient        IN NUMBER,
        i_episode        IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER,
        o_components     OUT pk_types.cursor_type,
        o_ds_target      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    BEGIN
    
        l_return := pk_dyn_form.get_full_items_by_name(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_patient,
                                                       i_episode        => i_episode,
                                                       i_component_name => i_component_name,
                                                       i_action         => i_action,
                                                       o_components     => o_components,
                                                       o_ds_target      => o_ds_target,
                                                       o_error          => o_error);
        RETURN l_return;
    
    END get_full_items_by_name;

    FUNCTION get_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_mode           IN NUMBER, -- edit, new, submit, N/A
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_tbl_data       IN table_table_varchar,
        o_result         OUT pk_types.cursor_type, -- result cursor
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_dyn_form_values.get_values(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_episode        => i_episode,
                                             i_patient        => i_patient,
                                             i_action         => i_mode,
                                             i_root_name      => i_root_name,
                                             i_curr_component => i_curr_component,
                                             i_tbl_id_pk      => i_tbl_id_pk,
                                             i_tbl_mkt_rel    => i_tbl_mkt_rel,
											 i_tbl_int_name   => i_tbl_int_name,
                                             i_value          => i_value,
                                             i_value_mea      => i_value_mea,
                                             i_value_desc     => i_value_desc,
                                             i_value_clob     => i_value_clob,
                                             i_tbl_data       => i_tbl_data,
                                             o_result         => o_result,
                                             o_error          => o_error);
    
    END get_values;

    FUNCTION get_values_submit
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_tbl_data       IN table_table_varchar,
        o_result         OUT pk_types.cursor_type, -- result cursor
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_action_submit CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
    BEGIN
    
        RETURN get_values(i_lang           => i_lang,
                          i_prof           => i_prof,
                          i_episode        => i_episode,
                          i_patient        => i_patient,
                          i_mode           => k_action_submit,
                          i_root_name      => i_root_name,
                          i_curr_component => i_curr_component,
                          i_tbl_id_pk      => i_tbl_id_pk,
                          i_tbl_mkt_rel    => i_tbl_mkt_rel,
						  i_tbl_int_name   => i_tbl_int_name,
                          i_value          => i_value,
                          i_value_mea      => i_value_mea,
                          i_value_desc     => i_value_desc,
                          i_value_clob     => i_value_clob,
                          i_tbl_data       => i_tbl_data,
                          o_result         => o_result,
                          o_error          => o_error);
    
    END get_values_submit;

    FUNCTION get_custom_multichoice
    (
        i_lang                 IN NUMBER, -- standard parameters
        i_prof                 IN profissional, -- standard parameters
        i_episode              IN NUMBER, -- standard parameters
        i_patient              IN NUMBER, -- standard parameters
        i_root_name            in varchar2,
        i_service_name_curr    IN VARCHAR2, -- name of component
        i_internal_name_origin IN table_varchar, -- dependency fields
        i_internal_name_values IN table_table_varchar, -- values of dependency fields
        o_result               OUT pk_types.cursor_type, -- cursor with result ( t_row_core_domain struct )
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_dyn_form_values.get_custom_multichoice(i_lang                 => i_lang,
                                                         i_prof                 => i_prof,
                                                         i_episode              => i_episode,
                                                         i_patient              => i_patient,
                                                         i_root_name            => i_root_name,
                                                         i_service_name_curr    => i_service_name_curr,
                                                         i_internal_name_origin => i_internal_name_origin,
                                                         i_internal_name_values => i_internal_name_values,
                                                         o_result               => o_result,
                                                         o_error                => o_error);
    
    END get_custom_multichoice;

    FUNCTION get_id_mkt_rel_dest
    (
        i_lang        IN NUMBER,
		i_prof        in profissional,
        i_id_mkt_orig IN table_number,
        o_result      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_dyn_form.get_id_mkt_rel_dest(i_lang        => i_lang,
                                               i_id_mkt_orig => i_id_mkt_orig,
                                               o_result      => o_result,
                                               o_error       => o_error);
    
    END get_id_mkt_rel_dest;


    FUNCTION get_values_multi
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_mode           IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN tt_table_varchar,
        i_value_mea      IN tt_table_varchar,
        i_value_desc     IN tt_table_varchar,
        i_value_clob     IN table_table_clob,
        i_tbl_data       IN table_table_varchar,
        o_result         OUT pk_types.cursor_type, -- result cursor
        o_error          OUT t_error_out
    ) RETURN BOOLEAN is
    begin
      
        RETURN pk_dyn_form_values.get_values_multi(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => i_episode,
                                                   i_patient        => i_patient,
                                                   i_action         => i_mode,
                                                   i_root_name      => i_root_name,
                                                   i_curr_component => i_curr_component,
                                                   i_tbl_id_pk      => i_tbl_id_pk,
                                                   i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                   i_tbl_int_name   => i_tbl_int_name,
                                                   i_value          => i_value,
                                                   i_value_mea      => i_value_mea,
                                                   i_value_desc     => i_value_desc,
                                                   i_value_clob     => i_value_clob,
                                                   i_tbl_data       => i_tbl_data,
                                                   o_result         => o_result,
                                                   o_error          => o_error);
    
    END get_values_multi;

    FUNCTION get_values_submit_multi
                  (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN tt_table_varchar,
        i_value_mea      IN tt_table_varchar,
        i_value_desc     IN tt_table_varchar,
        i_value_clob     IN table_table_clob,
        i_tbl_data       IN table_table_varchar,
        o_result         OUT pk_types.cursor_type, -- result cursor
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_action_submit CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
    BEGIN
    
        RETURN get_values_multi(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => i_episode,
                                i_patient        => i_patient,
                                i_mode           => k_action_submit,
                                i_root_name      => i_root_name,
                                i_curr_component => i_curr_component,
                                i_tbl_id_pk      => i_tbl_id_pk,
                                i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                i_tbl_int_name   => i_tbl_int_name,
                                i_value          => i_value,
                                i_value_mea      => i_value_mea,
                                i_value_desc     => i_value_desc,
                                i_value_clob     => i_value_clob,
                                i_tbl_data       => i_tbl_data,
                                o_result         => o_result,
                                o_error          => o_error);

    END get_values_submit_multi;

BEGIN

    -- Initializes log context
    pk_alertlog.log_init(object_name => k_pck_name);

END pk_ux_dyn_form;
/
