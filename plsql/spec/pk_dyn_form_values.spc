/*-- Last Change Revision: $Rev: 2011151 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-03-18 15:47:51 +0000 (sex, 18 mar 2022) $*/

CREATE OR REPLACE PACKAGE pk_dyn_form_values AS 


    -- ******************************************
    -- ******************************************

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
    ) RETURN BOOLEAN;

    FUNCTION get_event_value
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_value   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar, --fot unitmeasure, currency of value
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_tbl_data       in table_table_varchar,
        o_result         OUT pk_types.cursor_type, -- result cursor
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_values_multi
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
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
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION process_multi_form_result
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_root_name IN VARCHAR2,
        o_result    IN OUT t_tbl_ds_get_value,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_dyn_form_values;
/
