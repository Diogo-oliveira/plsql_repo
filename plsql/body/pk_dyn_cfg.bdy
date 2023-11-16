CREATE OR REPLACE PACKAGE BODY pk_dyn_cfg AS

    PROCEDURE ins_mkt_rel
    (
        i_row      IN ds_cmpt_mkt_rel%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    ) IS
    BEGIN
    
        INSERT INTO ds_cmpt_mkt_rel
            (id_ds_cmpt_mkt_rel,
             id_market,
             id_ds_component_parent,
             internal_name_parent,
             flg_component_type_parent,
             id_ds_component_child,
             internal_name_child,
             flg_component_type_child,
             rank,
             id_software,
             gender,
             age_min_value,
             age_min_unit_measure,
             age_max_value,
             age_max_unit_measure,
             id_unit_measure,
             id_unit_measure_subtype,
             max_len,
             min_value,
             max_value,
             flg_def_event_type,
             id_profile_template,
             position,
             flg_configurable,
             slg_internal_name,
             multi_option_column,
             code_domain,
             service_name,
             id_category,
             min_len,
             ds_alias,
             code_alt_desc,
             service_params,
             flg_exp_type,
             input_expression,
             input_mask,
             desc_function,
             comp_size,
             comp_offset,
             flg_hidden,
             flg_clearable,
             code_validation_message,
             flg_label_visible,
             internal_sample_text_type,
             flg_data_type2,
             TEXT_LINE_NR)
        VALUES
            (i_row.id_ds_cmpt_mkt_rel,
             i_row.id_market,
             i_row.id_ds_component_parent,
             i_row.internal_name_parent,
             i_row.flg_component_type_parent,
             i_row.id_ds_component_child,
             i_row.internal_name_child,
             i_row.flg_component_type_child,
             i_row.rank,
             i_row.id_software,
             i_row.gender,
             i_row.age_min_value,
             i_row.age_min_unit_measure,
             i_row.age_max_value,
             i_row.age_max_unit_measure,
             i_row.id_unit_measure,
             i_row.id_unit_measure_subtype,
             i_row.max_len,
             i_row.min_value,
             i_row.max_value,
             i_row.flg_def_event_type,
             i_row.id_profile_template,
             i_row.position,
             i_row.flg_configurable,
             i_row.slg_internal_name,
             i_row.multi_option_column,
             i_row.code_domain,
             i_row.service_name,
             i_row.id_category,
             i_row.min_len,
             i_row.ds_alias,
             i_row.code_alt_desc,
             i_row.service_params,
             i_row.flg_exp_type,
             i_row.input_expression,
             i_row.input_mask,
             i_row.desc_function,
             i_row.comp_size,
             i_row.comp_offset,
             i_row.flg_hidden,
             i_row.flg_clearable,
             i_row.code_validation_message,
             i_row.flg_label_visible,
             i_row.internal_sample_text_type,
             i_row.flg_data_type2,
             i_row.TEXT_LINE_NR);
    EXCEPTION
        WHEN dup_val_on_index THEN
            IF i_validate
            THEN
                RAISE;
            END IF;
    END ins_mkt_rel;

    ------------------------
    PROCEDURE ins_comp
    (
        i_row      IN ds_component%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    ) IS
    BEGIN
    
        INSERT INTO ds_component
            (id_ds_component,
             internal_name,
             flg_component_type,
             code_ds_component,
             flg_data_type,
             slg_internal_name,
             max_len,
             min_value,
             max_value,
             gender,
             age_min_value,
             age_min_unit_measure,
             age_max_value,
             age_max_unit_measure,
             id_unit_measure,
             id_unit_measure_subtype,
             multi_option_column,
             code_domain,
             service_name,
             internal_sample_text_type,
             flg_wrap_text,
             flg_repeatable)
        VALUES
            (i_row.id_ds_component,
             i_row.internal_name,
             i_row.flg_component_type,
             i_row.code_ds_component,
             i_row.flg_data_type,
             i_row.slg_internal_name,
             i_row.max_len,
             i_row.min_value,
             i_row.max_value,
             i_row.gender,
             i_row.age_min_value,
             i_row.age_min_unit_measure,
             i_row.age_max_value,
             i_row.age_max_unit_measure,
             i_row.id_unit_measure,
             i_row.id_unit_measure_subtype,
             i_row.multi_option_column,
             i_row.code_domain,
             i_row.service_name,
             i_row.internal_sample_text_type,
             i_row.flg_wrap_text,
             i_row.flg_repeatable);
    EXCEPTION
        WHEN dup_val_on_index THEN
            IF i_validate
            THEN
                RAISE;
            END IF;
    END ins_comp;

    ----
    PROCEDURE ins_event_target
    (
        i_row      IN ds_event_target%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    ) IS
    BEGIN
    
        INSERT INTO ds_event_target
            (id_ds_event_target, id_ds_event, id_ds_cmpt_mkt_rel, flg_event_type, field_mask)
        VALUES
            (i_row.id_ds_event_target,
             i_row.id_ds_event,
             i_row.id_ds_cmpt_mkt_rel,
             i_row.flg_event_type,
             i_row.field_mask);
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            IF i_validate
            THEN
                RAISE;
            END IF;
    END ins_event_target;

    PROCEDURE ins_event
    (
        i_row      IN ds_event%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    ) IS
    BEGIN
    
        INSERT INTO ds_event
            (id_ds_event, id_ds_cmpt_mkt_rel, VALUE, flg_type, id_action)
        VALUES
            (i_row.id_ds_event, i_row.id_ds_cmpt_mkt_rel, i_row.value, i_row.flg_type, i_row.id_action);
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            IF i_validate
            THEN
                RAISE;
            END IF;
    END ins_event;

    --*********************************
    PROCEDURE ins_def_event
    (
        i_row      IN ds_def_event%ROWTYPE,
        i_validate IN BOOLEAN DEFAULT TRUE
    ) IS
    BEGIN
    
        INSERT INTO ds_def_event
            (id_def_event, id_ds_cmpt_mkt_rel, flg_event_type, id_action, flg_default)
        VALUES
            (i_row.id_def_event, i_row.id_ds_cmpt_mkt_rel, i_row.flg_event_type, i_row.id_action, i_row.flg_default);
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            IF i_validate
            THEN
                RAISE;
            END IF;
        
    END ins_def_event;

END pk_dyn_cfg;
/
