/*-- Last Change Revision: $Rev: 2052476 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-12-07 14:27:27 +0000 (qua, 07 dez 2022) $*/

--
CREATE OR REPLACE PACKAGE BODY pk_dyn_form AS

    k_yes      CONSTANT t_low_char := 'Y';
    k_no       CONSTANT t_low_char := 'N';
    k_pck_name CONSTANT t_low_char := pk_alertlog.who_am_i();

    k_age_type_limit_min CONSTANT t_low_char := pk_dyn_form_constant.get_age_type_limit_min();
    k_age_type_limit_max CONSTANT t_low_char := pk_dyn_form_constant.get_age_type_limit_max();
    k_mask_year          CONSTANT t_low_char := pk_dyn_form_constant.get_mask_year();

    k_gender_unknown CONSTANT t_low_char := pk_dyn_form_constant.get_gender_unknown();

    k_id_unit_measure_year CONSTANT t_big_num := pk_dyn_form_constant.get_id_unit_measure_year();
    k_default_action       CONSTANT t_big_num := pk_dyn_form_constant.get_default_action();

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    
    END iif;

    -- validated
    FUNCTION get_default_action RETURN NUMBER IS
    BEGIN
        RETURN k_default_action;
    END get_default_action;

    /*
      * Generic function for processing error messages.
      ** @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    PROCEDURE process_error
    (
        i_lang     IN NUMBER,
        i_err_text IN VARCHAR2,
        i_function IN VARCHAR2,
        o_error    OUT t_error_out
    ) IS
    BEGIN
    
        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => SQLCODE,
                                          i_sqlerrm  => SQLERRM,
                                          i_message  => i_err_text,
                                          i_owner    => 'ALERT',
                                          i_package  => k_pck_name,
                                          i_function => i_function,
                                          o_error    => o_error);
    
        pk_utils.undo_changes;
    
    END process_error;

    FUNCTION init_action(i_action IN NUMBER) RETURN NUMBER IS
        l_return t_big_num;
    BEGIN
    
        l_return := coalesce(i_action, k_default_action);
        RETURN l_return;
    
    END init_action;

    /*
      * Get id of component given internal_name
      *
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_id_component_by_name(i_name IN VARCHAR2) RETURN NUMBER IS
        tbl_id   table_number;
        l_return t_big_num;
    BEGIN
    
        SELECT id_ds_component
          BULK COLLECT
          INTO tbl_id
          FROM v_ds_component
         WHERE internal_name = i_name;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_component_by_name;

    /*
      * Get internal_name of component given id
      *
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * --validated
      */
    FUNCTION get_component_name_by_id(i_id_component IN NUMBER) RETURN VARCHAR2 IS
        tbl_name table_varchar;
        l_return VARCHAR2(1000 CHAR);
    BEGIN
    
        SELECT dc.internal_name
          BULK COLLECT
          INTO tbl_name
          FROM v_ds_component dc
         WHERE dc.id_ds_component = i_id_component;
    
        IF tbl_name.count > 0
        THEN
            l_return := tbl_name(1);
        END IF;
    
        RETURN l_return;
    
    END get_component_name_by_id;

    /*
      * Get whole tree with default action, from base configuration given root component_name
      *
      * @return table function, returning rows of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_dyn_tree_mkt
    (
        i_component_name IN VARCHAR2,
        i_market         IN NUMBER,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table IS
        tbl_tree t_dyn_tree_table;
    BEGIN
    
        SELECT t_dyn_tree_row(id_ds_cmpt_mkt_rel        => dscm.id_ds_cmpt_mkt_rel,
                              id_ds_cmpt_inst_rel       => 0,
                              id_institution            => 0,
                              id_ds_component_parent    => dscm.id_ds_component_parent,
                              code_component_parent     => dscm.code_component_parent,
                              internal_name_parent      => dscm.internal_name_parent,
                              flg_component_type_parent => dscm.flg_component_type_parent,
                              id_ds_component_child     => dscm.id_ds_component_child,
                              code_component_child      => dscm.code_component_child,
                              internal_name_child       => dscm.internal_name_child,
                              flg_component_type_child  => dscm.flg_component_type_child,
                              id_profile_template       => dscm.id_profile_template,
                              id_category               => dscm.id_category,
                              id_software               => dscm.id_software,
                              id_market                 => dscm.id_market,
                              rank                      => dscm.rank,
                              gender                    => dscm.gender,
                              age_min_value             => dscm.age_min_value,
                              age_min_unit_measure      => dscm.age_min_unit_measure,
                              age_max_value             => dscm.age_max_value,
                              age_max_unit_measure      => dscm.age_max_unit_measure,
                              id_unit_measure           => dscm.id_unit_measure,
                              id_unit_measure_subtype   => dscm.id_unit_measure_subtype,
                              max_len                   => dscm.max_len,
                              min_len                   => dscm.min_len,
                              min_value                 => dscm.min_value,
                              max_value                 => dscm.max_value,
                              position                  => dscm.position,
                              flg_configurable          => dscm.flg_configurable,
                              --slg_internal_name         => dscm.slg_internal_name,
                              --multi_option_column       => dscm.multi_option_column,
                              --code_domain               => dscm.code_domain,
                              --service_name              => dscm.service_name,
                              service_params => dscm.service_params,
                              --flg_default_value   => dscm.flg_default_value,
                              flg_multichoice           => dscm.flg_multichoice,
                              multichoice_service       => dscm.multichoice_service,
                              id_action                 => dscm.id_action,
                              flg_event_type            => dscm.flg_event_type,
                              comp_size                 => dscm.comp_size,
                              ds_alias                  => dscm.ds_alias,
                              code_alt_desc             => dscm.code_alt_desc,
                              desc_function             => dscm.desc_function,
                              flg_exp_type              => dscm.flg_exp_type,
                              input_expression          => dscm.input_expression,
                              input_mask                => dscm.input_mask,
                              comp_offset               => dscm.comp_offset,
                              flg_hidden                => dscm.flg_hidden,
                              placeholder               => dscm.placeholder,
                              code_validation_msg       => dscm.code_validation_message,
                              flg_clearable             => dscm.flg_clearable,
                              crate_identifier          => dscm.crate_identifier,
                              flg_label_visible         => dscm.flg_label_visible,
                              internal_sample_text_type => dscm.internal_sample_text_type,
                              rn                        => rownum,
                              flg_repeatable            => dscm.flg_repeatable,
                              flg_data_type2            => dscm.flg_data_type2,
                              text_line_nr              => dscm.text_line_nr )
          BULK COLLECT
          INTO tbl_tree
          FROM (SELECT tt.*
                  FROM (SELECT ddex.id_action,
                               ddex.flg_event_type,
                               dc.code_ds_component code_component_child,
                               dp.code_ds_component code_component_parent,
                               dc.flg_repeatable,
                               dscmx.*
                          FROM v_ds_cmpt_mkt_rel dscmx
                          LEFT JOIN v_ds_component dp
                            ON dp.id_ds_component = dscmx.id_ds_component_parent
                          JOIN v_ds_component dc
                            ON dc.id_ds_component = dscmx.id_ds_component_child
                          LEFT JOIN v_ds_def_event ddex
                            ON ddex.id_ds_cmpt_mkt_rel = dscmx.id_ds_cmpt_mkt_rel
                         WHERE dscmx.id_market IN (0, i_market)) tt
                 WHERE tt.id_action = i_action
                    OR (tt.id_action IS NULL)
                   AND rownum > 0) dscm
        CONNECT BY PRIOR dscm.id_ds_component_child = dscm.id_ds_component_parent
         START WITH dscm.internal_name_child = i_component_name
         ORDER SIBLINGS BY dscm.rank, dscm.position;
    
        RETURN tbl_tree;
    
    END get_dyn_tree_mkt;

    /*
      * Get local configuration with default action, from local configuration given root component_name
      *
      * @return table function, returning rows of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_dyn_cfg_inst
    (
        i_prof        IN profissional,
        i_profile     IN NUMBER,
        i_category    IN NUMBER,
        i_tbl_mkt_rel IN t_dyn_tree_table,
        i_action      IN NUMBER
    ) RETURN t_dyn_tree_table IS
        tbl_cfg t_dyn_tree_table;
    BEGIN
    
        SELECT t_dyn_tree_row(id_ds_cmpt_mkt_rel        => tt.id_ds_cmpt_mkt_rel,
                              id_ds_cmpt_inst_rel       => tt.id_ds_cmpt_inst_rel,
                              id_institution            => tt.id_institution,
                              id_ds_component_parent    => tt.id_ds_component_parent,
                              code_component_parent     => tt.code_component_parent,
                              internal_name_parent      => tt.internal_name_parent,
                              flg_component_type_parent => tt.flg_component_type_parent,
                              id_ds_component_child     => tt.id_ds_component_child,
                              code_component_child      => tt.code_component_child,
                              internal_name_child       => tt.internal_name_child,
                              flg_component_type_child  => tt.flg_component_type_child,
                              id_profile_template       => tt.id_profile_template,
                              id_category               => tt.id_category,
                              id_software               => tt.id_software,
                              id_market                 => tt.id_market,
                              rank                      => tt.rank,
                              gender                    => tt.gender,
                              age_min_value             => tt.age_min_value,
                              age_min_unit_measure      => tt.age_min_unit_measure,
                              age_max_value             => tt.age_max_value,
                              age_max_unit_measure      => tt.age_max_unit_measure,
                              id_unit_measure           => tt.id_unit_measure,
                              id_unit_measure_subtype   => tt.id_unit_measure_subtype,
                              max_len                   => tt.max_len,
                              min_len                   => tt.min_len,
                              min_value                 => tt.min_value,
                              max_value                 => tt.max_value,
                              position                  => tt.position,
                              flg_configurable          => tt.flg_configurable,
                              --slg_internal_name         => tt.slg_internal_name,
                              --multi_option_column       => tt.multi_option_column,
                              --code_domain               => tt.code_domain,
                              --service_name              => tt.service_name,
                              service_params => tt.service_params,
                              --flg_default_value   => tt.flg_default_value,
                              flg_multichoice           => tt.flg_multichoice,
                              multichoice_service       => tt.multichoice_service,
                              id_action                 => tt.id_action,
                              flg_event_type            => tt.flg_event_type,
                              comp_size                 => tt.comp_size,
                              ds_alias                  => tt.ds_alias,
                              code_alt_desc             => tt.code_alt_desc,
                              desc_function             => tt.desc_function,
                              flg_exp_type              => tt.flg_exp_type,
                              input_expression          => tt.input_expression,
                              input_mask                => tt.input_mask,
                              comp_offset               => tt.comp_offset,
                              flg_hidden                => tt.flg_hidden,
                              placeholder               => tt.placeholder,
                              code_validation_msg       => tt.code_validation_msg,
                              flg_clearable             => tt.flg_clearable,
                              crate_identifier          => tt.crate_identifier,
                              flg_label_visible         => tt.flg_label_visible,
                              internal_sample_text_type => tt.internal_sample_text_type,
                              rn                        => tt.rnn,
                              flg_repeatable            => tt.flg_repeatable,
                              flg_data_type2            => tt.flg_data_type2,
                              text_line_nr              => tt.text_line_nr )
          BULK COLLECT
          INTO tbl_cfg
          FROM (SELECT dsx.id_ds_cmpt_mkt_rel,
                       dsx.id_ds_cmpt_inst_rel,
                       dsx.id_institution,
                       dsx.id_ds_component_parent,
                       dsr.code_component_parent,
                       dsr.internal_name_parent,
                       dsr.flg_component_type_parent,
                       dsx.id_ds_component_child,
                       dsr.code_component_child,
                       dsr.internal_name_child,
                       dsr.flg_component_type_child,
                       dsx.id_profile_template,
                       dsx.id_category,
                       dsx.id_software,
                       dsr.id_market,
                       dsx.rank,
                       dsx.gender,
                       dsx.age_min_value,
                       dsx.age_min_unit_measure,
                       dsx.age_max_value,
                       dsx.age_max_unit_measure,
                       dsx.id_unit_measure,
                       dsx.id_unit_measure_subtype,
                       dsx.max_len,
                       dsx.min_len,
                       dsx.min_value,
                       dsx.max_value,
                       dsx.position,
                       dsr.flg_configurable,
                       --dsr.slg_internal_name,
                       --dsr.multi_option_column,
                       --dsr.code_domain,
                       --dsr.service_name,
                       dsr.service_params,
                       --dsx.flg_default_value,
                       dsr.flg_multichoice,
                       dsr.multichoice_service,
                       dsx.comp_size,
                       ddei.id_action id_action, --ddei.id_action,
                       ddei.flg_event_type flg_event_type, --ddei.flg_event_type,
                       dsr.ds_alias,
                       dsr.code_alt_desc,
                       dsr.desc_function,
                       dsr.flg_exp_type,
                       dsr.input_expression,
                       dsr.input_mask,
                       dsx.comp_offset,
                       'N' flg_hidden,
                       dsr.placeholder,
                       dsr.code_validation_msg,
                       dsr.flg_clearable,
                       dsr.crate_identifier,
                       dsr.flg_label_visible,
                       dsr.internal_sample_text_type,
                       rownum rn,
                       row_number() over(PARTITION BY dsx.id_ds_component_parent, dsx.id_ds_component_child ORDER BY dsx.id_software DESC, dsx.id_category DESC, dsx.id_profile_template DESC) rnn,
                       dsr.flg_repeatable,
                       dsr.flg_data_type2,
                       dsr.text_line_nr
                  FROM v_ds_cmpt_inst_rel dsx
                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE ttt ROWS=1) */
                        ttt.*
                         FROM TABLE(i_tbl_mkt_rel) ttt) dsr
                    ON dsr.id_ds_cmpt_mkt_rel = dsx.id_ds_cmpt_mkt_rel
                  LEFT JOIN v_ds_def_event_inst ddei
                    ON ddei.id_ds_cmpt_inst_rel = dsx.id_ds_cmpt_inst_rel
                   AND (ddei.id_action = i_action)
                 WHERE dsr.flg_configurable != k_no
                   AND dsx.id_institution = i_prof.institution
                   AND dsx.id_profile_template IN (i_profile, 0)
                   AND dsx.id_software IN (i_prof.software, 0)
                   AND dsx.id_category IN (i_category, 0)) tt
         WHERE tt.rnn = 1
         ORDER BY tt.rn;
    
        RETURN tbl_cfg;
    
    END get_dyn_cfg_inst;

    /*
      * returns given array filterd by age and gender
      *
      * @return table function, returning rows of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_union_by_age_gender
    (
        i_gender   IN VARCHAR2,
        i_age      IN NUMBER,
        i_tbl_tree IN t_dyn_tree_table
    ) RETURN t_dyn_tree_table IS
        tbl_result t_dyn_tree_table;
    BEGIN
    
        SELECT t_dyn_tree_row(id_ds_cmpt_mkt_rel        => tbl.id_ds_cmpt_mkt_rel,
                              id_ds_cmpt_inst_rel       => tbl.id_ds_cmpt_inst_rel,
                              id_institution            => tbl.id_institution,
                              id_ds_component_parent    => tbl.id_ds_component_parent,
                              code_component_parent     => tbl.code_component_parent,
                              internal_name_parent      => tbl.internal_name_parent,
                              flg_component_type_parent => tbl.flg_component_type_parent,
                              id_ds_component_child     => tbl.id_ds_component_child,
                              code_component_child      => tbl.code_component_child,
                              internal_name_child       => tbl.internal_name_child,
                              flg_component_type_child  => tbl.flg_component_type_child,
                              id_profile_template       => tbl.id_profile_template,
                              id_category               => tbl.id_category,
                              id_software               => tbl.id_software,
                              id_market                 => tbl.id_market,
                              rank                      => tbl.rank,
                              gender                    => tbl.gender,
                              age_min_value             => tbl.age_min_value,
                              age_min_unit_measure      => tbl.age_min_unit_measure,
                              age_max_value             => tbl.age_max_value,
                              age_max_unit_measure      => tbl.age_max_unit_measure,
                              id_unit_measure           => tbl.id_unit_measure,
                              id_unit_measure_subtype   => tbl.id_unit_measure_subtype,
                              max_len                   => tbl.max_len,
                              min_len                   => tbl.min_len,
                              min_value                 => tbl.min_value,
                              max_value                 => tbl.max_value,
                              position                  => tbl.position,
                              flg_configurable          => tbl.flg_configurable,
                              --slg_internal_name         => tbl.slg_internal_name,
                              --multi_option_column       => tbl.multi_option_column,
                              --code_domain               => tbl.code_domain,
                              --service_name              => tbl.service_name,
                              service_params => tbl.service_params,
                              --flg_default_value   => tbl.flg_default_value,
                              flg_multichoice           => tbl.flg_multichoice,
                              multichoice_service       => tbl.multichoice_service,
                              id_action                 => tbl.id_action,
                              flg_event_type            => tbl.flg_event_type,
                              comp_size                 => tbl.comp_size,
                              ds_alias                  => tbl.ds_alias,
                              code_alt_desc             => tbl.code_alt_desc,
                              desc_function             => tbl.desc_function,
                              flg_exp_type              => tbl.flg_exp_type,
                              input_expression          => tbl.input_expression,
                              input_mask                => tbl.input_mask,
                              comp_offset               => tbl.comp_offset,
                              flg_hidden                => tbl.flg_hidden,
                              placeholder               => tbl.placeholder,
                              code_validation_msg       => tbl.code_validation_msg,
                              flg_clearable             => tbl.flg_clearable,
                              crate_identifier          => tbl.crate_identifier,
                              flg_label_visible         => tbl.flg_label_visible,
                              internal_sample_text_type => tbl.internal_sample_text_type,
                              rn                        => tbl.rn,
                              flg_repeatable            => tbl.flg_repeatable,
                              flg_data_type2            => tbl.flg_data_type2,
                              text_line_nr              => tbl.text_line_nr )
          BULK COLLECT
          INTO tbl_result
          FROM TABLE(i_tbl_tree) tbl
         WHERE pk_dyn_form.check_age_limits_min(i_pat_age      => i_age,
                                                i_age_limit    => tbl.age_min_value,
                                                i_unit_measure => tbl.age_min_unit_measure) = k_yes
           AND pk_dyn_form.check_age_limits_max(i_pat_age      => i_age,
                                                i_age_limit    => tbl.age_max_value,
                                                i_unit_measure => tbl.age_max_unit_measure) = k_yes
           AND coalesce(tbl.gender, i_gender, k_gender_unknown) = coalesce(i_gender, k_gender_unknown);
    
        RETURN tbl_result;
    END get_union_by_age_gender;

    --**************
    --**************

    /*
      * Merge martket configuration with local configs setting  most significant first
      *
      * @return table function, returning rows of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/05
    * -- validated
      */
    FUNCTION get_union
    (
        i_tbl_mkt_rel  IN t_dyn_tree_table,
        i_tbl_inst_rel IN t_dyn_tree_table
    ) RETURN t_dyn_tree_table IS
        tbl_mkt t_dyn_tree_table := t_dyn_tree_table();
        --tbl_inst         t_dyn_tree_table := t_dyn_tree_table();
        tbl_union        t_dyn_tree_table := t_dyn_tree_table();
        tbl_return       t_dyn_tree_table;
        l_id_institution t_big_num;
        l_id_market      t_big_num;
    BEGIN
    
        --tbl_union := i_tbl_mkt_rel MULTISET UNION i_tbl_inst_rel;
        --
        IF i_tbl_inst_rel.count > 0
        THEN
            l_id_institution := i_tbl_inst_rel(1).id_institution;
        
            -- Remove MKT with FLG_CONFIGURABLE to Y
            <<lup_thru_mkt_rel>>
            FOR i IN 1 .. i_tbl_mkt_rel.count
            LOOP
            
                IF i_tbl_mkt_rel(i).flg_configurable = k_no
                THEN
                    tbl_mkt.extend();
                    tbl_mkt(tbl_mkt.count) := i_tbl_mkt_rel(i);
                END IF;
            
            END LOOP lup_thru_mkt_rel;
        
            tbl_union := tbl_mkt MULTISET UNION i_tbl_inst_rel;
        
        ELSE
        
            IF i_tbl_mkt_rel.count > 0
            THEN
                tbl_union   := i_tbl_mkt_rel;
                l_id_market := i_tbl_mkt_rel(1).id_market;
            END IF;
        
        END IF;
    
        --
        SELECT t_dyn_tree_row(id_ds_cmpt_mkt_rel        => dsi.id_ds_cmpt_mkt_rel,
                              id_ds_cmpt_inst_rel       => dsi.id_ds_cmpt_inst_rel,
                              id_institution            => l_id_institution,
                              id_ds_component_parent    => dsi.id_ds_component_parent,
                              code_component_parent     => dsi.code_component_parent,
                              internal_name_parent      => dsi.internal_name_parent,
                              flg_component_type_parent => dsi.flg_component_type_parent,
                              id_ds_component_child     => dsi.id_ds_component_child,
                              code_component_child      => dsi.code_component_child,
                              internal_name_child       => dsi.internal_name_child,
                              flg_component_type_child  => dsi.flg_component_type_child,
                              id_profile_template       => dsi.id_profile_template,
                              id_category               => dsi.id_category,
                              id_software               => dsi.id_software,
                              id_market                 => l_id_market,
                              rank                      => dsi.rank,
                              gender                    => dsi.gender,
                              age_min_value             => dsi.age_min_value,
                              age_min_unit_measure      => dsi.age_min_unit_measure,
                              age_max_value             => dsi.age_max_value,
                              age_max_unit_measure      => dsi.age_max_unit_measure,
                              id_unit_measure           => dsi.id_unit_measure,
                              id_unit_measure_subtype   => dsi.id_unit_measure_subtype,
                              max_len                   => dsi.max_len,
                              min_len                   => dsi.min_len,
                              min_value                 => dsi.min_value,
                              max_value                 => dsi.max_value,
                              position                  => dsi.position,
                              flg_configurable          => dsi.flg_configurable,
                              --slg_internal_name         => dsi.slg_internal_name,
                              --multi_option_column       => dsi.multi_option_column,
                              --code_domain               => dsi.code_domain,
                              --service_name              => dsi.service_name,
                              service_params => dsi.service_params,
                              --flg_default_value   => dsi.flg_default_value,
                              flg_multichoice           => dsi.flg_multichoice,
                              multichoice_service       => dsi.multichoice_service,
                              id_action                 => dsi.id_action,
                              flg_event_type            => dsi.flg_event_type,
                              comp_size                 => dsi.comp_size,
                              ds_alias                  => dsi.ds_alias,
                              code_alt_desc             => dsi.code_alt_desc,
                              desc_function             => dsi.desc_function,
                              flg_exp_type              => dsi.flg_exp_type,
                              input_expression          => dsi.input_expression,
                              input_mask                => dsi.input_mask,
                              comp_offset               => dsi.comp_offset,
                              flg_hidden                => dsi.flg_hidden,
                              placeholder               => dsi.placeholder,
                              code_validation_msg       => dsi.code_validation_msg,
                              flg_clearable             => dsi.flg_clearable,
                              crate_identifier          => dsi.crate_identifier,
                              flg_label_visible         => dsi.flg_label_visible,
                              internal_sample_text_type => dsi.internal_sample_text_type,
                              rn                        => dsi.rnx,
                              flg_repeatable            => dsi.flg_repeatable,
                              flg_data_type2            => dsi.flg_data_type2,
                              text_line_nr              => dsi.text_line_nr )
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT xsql.*,
                       row_number() over(PARTITION BY internal_name_parent, internal_name_child ORDER BY id_institution DESC) rnx
                  FROM TABLE(tbl_union) xsql) dsi
         WHERE dsi.rnx = 1;
    
        RETURN tbl_return;
    
    END get_union;

    /*
      * returns given array organized as a hierarquy
      *
      * @return id_component , root of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * validated
      */
    FUNCTION get_union_tree
    (
        i_id_root   IN NUMBER,
        i_tbl_union IN t_dyn_tree_table
    ) RETURN t_dyn_tree_table IS
        tbl_return t_dyn_tree_table;
    BEGIN
    
        SELECT t_dyn_tree_row(id_ds_cmpt_mkt_rel        => dsi.id_ds_cmpt_mkt_rel,
                              id_ds_cmpt_inst_rel       => dsi.id_ds_cmpt_inst_rel,
                              id_institution            => dsi.id_institution,
                              id_ds_component_parent    => dsi.id_ds_component_parent,
                              code_component_parent     => dsi.code_component_parent,
                              internal_name_parent      => dsi.internal_name_parent,
                              flg_component_type_parent => dsi.flg_component_type_parent,
                              id_ds_component_child     => dsi.id_ds_component_child,
                              code_component_child      => dsi.code_component_child,
                              internal_name_child       => dsi.internal_name_child,
                              flg_component_type_child  => dsi.flg_component_type_child,
                              id_profile_template       => dsi.id_profile_template,
                              id_category               => dsi.id_category,
                              id_software               => dsi.id_software,
                              id_market                 => dsi.id_market,
                              rank                      => dsi.rank,
                              gender                    => dsi.gender,
                              age_min_value             => dsi.age_min_value,
                              age_min_unit_measure      => dsi.age_min_unit_measure,
                              age_max_value             => dsi.age_max_value,
                              age_max_unit_measure      => dsi.age_max_unit_measure,
                              id_unit_measure           => dsi.id_unit_measure,
                              id_unit_measure_subtype   => dsi.id_unit_measure_subtype,
                              max_len                   => dsi.max_len,
                              min_len                   => dsi.min_len,
                              min_value                 => dsi.min_value,
                              max_value                 => dsi.max_value,
                              position                  => dsi.position,
                              flg_configurable          => dsi.flg_configurable,
                              --slg_internal_name         => dsi.slg_internal_name,
                              --multi_option_column       => dsi.multi_option_column,
                              --code_domain               => dsi.code_domain,
                              --service_name              => dsi.service_name,
                              service_params => dsi.service_params,
                              --flg_default_value   => dsi.flg_default_value,
                              flg_multichoice           => dsi.flg_multichoice,
                              multichoice_service       => dsi.multichoice_service,
                              id_action                 => dsi.id_action,
                              flg_event_type            => dsi.flg_event_type,
                              comp_size                 => dsi.comp_size,
                              ds_alias                  => dsi.ds_alias,
                              code_alt_desc             => dsi.code_alt_desc,
                              desc_function             => dsi.desc_function,
                              flg_exp_type              => dsi.flg_exp_type,
                              input_expression          => dsi.input_expression,
                              input_mask                => dsi.input_mask,
                              comp_offset               => dsi.comp_offset,
                              flg_hidden                => dsi.flg_hidden,
                              placeholder               => dsi.placeholder,
                              code_validation_msg       => dsi.code_validation_msg,
                              flg_clearable             => dsi.flg_clearable,
                              crate_identifier          => dsi.crate_identifier,
                              flg_label_visible         => dsi.flg_label_visible,
                              internal_sample_text_type => dsi.internal_sample_text_type,
                              rn                        => rownum,
                              flg_repeatable            => dsi.flg_repeatable,
                              flg_data_type2            => dsi.flg_data_type2,
                              text_line_nr              => dsi.text_line_nr)
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT
                /*+ OPT_ESTIMATE(TABLE xpto ROWS=1) */
                 xpto.*
                  FROM TABLE(i_tbl_union) xpto) dsi
        CONNECT BY PRIOR dsi.id_ds_component_child = dsi.id_ds_component_parent
         START WITH dsi.id_ds_component_child = i_id_root
         ORDER SIBLINGS BY dsi.rank, dsi.position;
    
        RETURN tbl_return;
    
    END get_union_tree;

    /*
      * Get components with default action, from base configuration given root component_name
      *
      * @return table function, returning rows of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_dyn_cfg_mkt
    (
        i_prof           IN profissional,
        i_profile        IN NUMBER,
        i_category       IN NUMBER,
        i_market         IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table IS
        tbl_tree t_dyn_tree_table;
    BEGIN
    
        SELECT t_dyn_tree_row(id_ds_cmpt_mkt_rel        => xcfg.id_ds_cmpt_mkt_rel,
                              id_ds_cmpt_inst_rel       => xcfg.id_ds_cmpt_inst_rel,
                              id_institution            => xcfg.id_institution,
                              id_ds_component_parent    => xcfg.id_ds_component_parent,
                              code_component_parent     => xcfg.code_component_parent,
                              internal_name_parent      => xcfg.internal_name_parent,
                              flg_component_type_parent => xcfg.flg_component_type_parent,
                              id_ds_component_child     => xcfg.id_ds_component_child,
                              code_component_child      => xcfg.code_component_child,
                              internal_name_child       => xcfg.internal_name_child,
                              flg_component_type_child  => xcfg.flg_component_type_child,
                              id_profile_template       => xcfg.id_profile_template,
                              id_category               => xcfg.id_category,
                              id_software               => xcfg.id_software,
                              id_market                 => xcfg.id_market,
                              rank                      => xcfg.rank,
                              gender                    => xcfg.gender,
                              age_min_value             => xcfg.age_min_value,
                              age_min_unit_measure      => xcfg.age_min_unit_measure,
                              age_max_value             => xcfg.age_max_value,
                              age_max_unit_measure      => xcfg.age_max_unit_measure,
                              id_unit_measure           => xcfg.id_unit_measure,
                              id_unit_measure_subtype   => xcfg.id_unit_measure_subtype,
                              max_len                   => xcfg.max_len,
                              min_len                   => xcfg.min_len,
                              min_value                 => xcfg.min_value,
                              max_value                 => xcfg.max_value,
                              position                  => xcfg.position,
                              flg_configurable          => xcfg.flg_configurable,
                              --slg_internal_name         => xcfg.slg_internal_name,
                              --multi_option_column       => xcfg.multi_option_column,
                              --code_domain               => xcfg.code_domain,
                              --service_name              => xcfg.service_name,
                              service_params => xcfg.service_params,
                              --flg_default_value   => xcfg.flg_default_value,
                              flg_multichoice           => xcfg.flg_multichoice,
                              multichoice_service       => xcfg.multichoice_service,
                              id_action                 => xcfg.id_action,
                              flg_event_type            => xcfg.flg_event_type,
                              comp_size                 => xcfg.comp_size,
                              ds_alias                  => xcfg.ds_alias,
                              code_alt_desc             => xcfg.code_alt_desc,
                              desc_function             => xcfg.desc_function,
                              flg_exp_type              => xcfg.flg_exp_type,
                              input_expression          => xcfg.input_expression,
                              input_mask                => xcfg.input_mask,
                              comp_offset               => xcfg.comp_offset,
                              flg_hidden                => xcfg.flg_hidden,
                              placeholder               => xcfg.placeholder,
                              code_validation_msg       => xcfg.code_validation_msg,
                              flg_clearable             => xcfg.flg_clearable,
                              crate_identifier          => xcfg.crate_identifier,
                              flg_label_visible         => xcfg.flg_label_visible,
                              internal_sample_text_type => xcfg.internal_sample_text_type,
                              rn                        => xcfg.rn,
                              flg_repeatable            => xcfg.flg_repeatable,
                              flg_data_type2            => xcfg.flg_data_type2,
                              text_line_nr              => xcfg.text_line_nr)
          BULK COLLECT
          INTO tbl_tree
          FROM (SELECT
                /*+ OPT_ESTIMATE(TABLE tt ROWS=1) */
                 xsql.*,
                 --row_number() over(PARTITION BY xsql.id_ds_component_parent, xsql.id_ds_component_child ORDER BY xsql.id_market DESC, xsql.id_software DESC, xsql.id_category DESC, xsql.id_profile_template DESC) rn1
                 dense_rank() over(PARTITION BY 1 ORDER BY xsql.id_market DESC, xsql.id_software DESC, xsql.id_category DESC, xsql.id_profile_template DESC) rn1
                  FROM (SELECT tt.*
                          FROM TABLE(pk_dyn_form.get_dyn_tree_mkt(i_component_name => i_component_name,
                                                                  i_market         => i_market,
                                                                  i_action         => i_action)) tt
                         WHERE tt.id_action = i_action
                            OR tt.id_action IS NULL) xsql
                  LEFT JOIN v_ds_def_event dde
                    ON dde.id_ds_cmpt_mkt_rel = xsql.id_ds_cmpt_mkt_rel
                   AND dde.id_action = i_action
                 WHERE xsql.id_market IN (i_market, 0)
                   AND xsql.id_software IN (i_prof.software, 0)
                   AND xsql.id_profile_template IN (i_profile, 0)
                   AND xsql.id_category IN (i_category, 0)) xcfg
         WHERE xcfg.rn1 = 1
         ORDER BY xcfg.rn;
    
        RETURN tbl_tree;
    
    END get_dyn_cfg_mkt;

    /*
      * Get components with default action, from local configuration ( first choice ) or base configuration( 2nd choice )
      * given root component_name
      *
      * @return table function, returning rows of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_dyn_cfg
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_patient        IN NUMBER,
        i_component_name IN VARCHAR2,
        i_action         IN NUMBER
    ) RETURN t_dyn_tree_table IS
        tbl_tree   t_dyn_tree_table := t_dyn_tree_table();
        tbl_mkt    t_dyn_tree_table := t_dyn_tree_table();
        tbl_inst   t_dyn_tree_table := t_dyn_tree_table();
        tbl_union  t_dyn_tree_table := t_dyn_tree_table();
        tbl_result t_dyn_tree_table := t_dyn_tree_table();
    
        l_id_market           t_big_num;
        l_id_category         t_big_num;
        l_id_profile_template t_big_num;
        l_profile             profile_template%ROWTYPE;
        l_component_name      t_low_char;
        l_id_action           t_big_num;
        l_pat_age             t_big_num;
        l_pat_gender          t_low_char;
        l_id_root             t_big_num;
    BEGIN
    
        l_id_action           := init_action(i_action);
        l_component_name      := upper(i_component_name);
        l_profile             := pk_access.get_profile(i_prof => i_prof);
        l_id_profile_template := l_profile.id_profile_template;
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_market           := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_pat_age             := pk_patient.get_pat_age_num(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_patient => i_patient,
                                                            i_type    => k_mask_year);
    
        l_id_root := get_id_component_by_name(i_name => l_component_name);
    
        l_pat_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
    
        tbl_mkt := get_dyn_cfg_mkt(i_prof           => i_prof,
                                   i_profile        => l_id_profile_template,
                                   i_category       => l_id_category,
                                   i_market         => l_id_market,
                                   i_component_name => l_component_name,
                                   i_action         => l_id_action);
    
        --return tbl_mkt;
    
        tbl_inst := get_dyn_cfg_inst(i_prof        => i_prof,
                                     i_profile     => l_id_profile_template,
                                     i_category    => l_id_category,
                                     i_tbl_mkt_rel => tbl_mkt,
                                     i_action      => l_id_action);
        --RETURN tbl_inst;
        tbl_union := get_union(i_tbl_mkt_rel => tbl_mkt, i_tbl_inst_rel => tbl_inst);
    
        tbl_tree := get_union_tree(i_id_root => l_id_root, i_tbl_union => tbl_union);
    
        tbl_result := get_union_by_age_gender(i_gender => l_pat_gender, i_age => l_pat_age, i_tbl_tree => tbl_tree);
    
        RETURN tbl_result;
    
    END get_dyn_cfg;

    -- get root name of given mkt_rel
    FUNCTION get_root_name_by_id_mkt_rel(i_id_mkt_rel IN NUMBER) RETURN VARCHAR2 IS
        tbl_name table_varchar;
        l_return VARCHAR2(0200 CHAR);
    BEGIN
    
        SELECT internal_name_child
          BULK COLLECT
          INTO tbl_name
          FROM v_ds_cmpt_mkt_rel x
         WHERE x.id_ds_cmpt_mkt_rel = i_id_mkt_rel;
    
        IF tbl_name.count > 0
        THEN
            l_return := tbl_name(1);
        END IF;
    
        RETURN l_return;
    
    END get_root_name_by_id_mkt_rel;

    FUNCTION get_dyn_cfg
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_patient    IN NUMBER,
        i_id_mkt_rel IN NUMBER,
        i_action     IN NUMBER
    ) RETURN t_dyn_tree_table IS
        tbl_return       t_dyn_tree_table := t_dyn_tree_table();
        l_component_name VARCHAR2(0200 CHAR);
    BEGIN
    
        l_component_name := get_root_name_by_id_mkt_rel(i_id_mkt_rel);
    
        IF l_component_name IS NOT NULL
        THEN
        
            tbl_return := get_dyn_cfg(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_patient        => i_patient,
                                      i_component_name => l_component_name,
                                      i_action         => i_action);
        
        END IF;
    
        RETURN tbl_return;
    
    END get_dyn_cfg;

    /*
      * Get root component , given scren_name
      *
      * @return id_component , root of tree
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_id_comp_by_screen(i_screen_name IN VARCHAR2) RETURN NUMBER IS
        tbl_id   table_number;
        l_return t_big_num;
    BEGIN
    
        SELECT id_ds_component
          BULK COLLECT
          INTO tbl_id
          FROM v_ds_screens
         WHERE screen_name = upper(i_screen_name);
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_comp_by_screen;

    /*
      * Function to be used for ux purpose.
      * Get all components configured , given root component_name
      *
      * @return true if success, false if any unexpected error occured.
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_dyn_items_comp_name
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_tbl_dyn_cfg IN t_dyn_tree_table,
        i_action      IN NUMBER,
        o_result      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_result FOR
            SELECT --dc.id_ds_component,
             xcfg.id_ds_cmpt_mkt_rel,
             xcfg.id_ds_component_parent,
             -- temp
             xcfg.code_alt_desc,
             dc.code_ds_component,
             -- temp
             CASE
                  WHEN xcfg.flg_label_visible = k_yes THEN
                   pk_dyn_form.get_dyn_desc(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_action    => i_action,
                                            i_node_type => xcfg.flg_component_type_child,
                                            i_tbl_codes => table_varchar(xcfg.desc_function,
                                                                         xcfg.code_alt_desc,
                                                                         xcfg.code_component_child,
                                                                         dc.code_root_title_add,
                                                                         dc.code_root_title_edit))
                  ELSE
                   NULL
              END desc_component,
             coalesce(xcfg.ds_alias, dc.internal_name) internal_name,
             dc.flg_data_type,
             coalesce(xcfg.internal_sample_text_type, dc.internal_sample_text_type) internal_sample_text_type,
             xcfg.id_ds_component_child,
             xcfg.rank,
             xcfg.max_len,
             xcfg.min_len,
             xcfg.min_value,
             xcfg.max_value,
             xcfg.position,
             coalesce(xcfg.flg_multichoice, dc.flg_multichoice) flg_multichoice,
             xcfg.comp_size,
             dc.flg_wrap_text,
             coalesce(xcfg.multichoice_service, dc.multichoice_service) multichoice_code,
             xcfg.service_params,
             xcfg.flg_event_type,
             xcfg.flg_exp_type,
             xcfg.input_expression,
             xcfg.input_mask,
             xcfg.comp_offset,
             xcfg.flg_hidden,
             pk_message.get_message(i_lang, xcfg.placeholder) placeholder,
             pk_message.get_message(i_lang, xcfg.code_validation_msg) validation_message,
             xcfg.flg_clearable,
             xcfg.crate_identifier,
             xcfg.rn,
             dc.flg_repeatable,
             xcfg.flg_data_type2,
             xcfg.text_line_nr
              FROM (SELECT /*+ OPT_ESTIMATE(TABLE tt ROWS=1) */
                     tt.*
                      FROM TABLE(i_tbl_dyn_cfg) tt) xcfg
              JOIN v_ds_component dc
                ON dc.id_ds_component = xcfg.id_ds_component_child
             ORDER BY xcfg.rn, xcfg.rank, xcfg.position;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            process_error(i_lang     => i_lang,
                          i_err_text => SQLERRM,
                          i_function => 'GET_DYN_ITEMS_COMP_NAME',
                          o_error    => o_error);
        
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_dyn_items_comp_name;

    /*
    * Get content of list of domain categorized by correspodning flg_type ( multichoice, sys_list, etc... )
    *
    * @return one or more domains
    *
    * @author Carlos Ferreira
    * @version
    * @since 2019/04
    */
    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar
    ) RETURN t_tbl_core_domain IS
    BEGIN
    
        RETURN pk_sysdomain.get_multichoice(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                            i_flg_type      => i_flg_type,
                                            i_internal_name => i_internal_name);
    
    END get_multichoice;

    /*
    * Function to be used for ux purpose.
    * Get content of list of multichoice,according corresponding i_flg_type
    *
    * @return true if success, false if any unexpected error occured.
    *
    * @author Carlos Ferreira
    * @version
    * @since 2019/04
    */
    FUNCTION get_multichoice
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_type      IN table_varchar,
        i_internal_name IN table_varchar,
        o_result        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_sysdomain.get_multichoice(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_flg_type      => i_flg_type,
                                            i_internal_name => i_internal_name,
                                            o_result        => o_result,
                                            o_error         => o_error);
    
    END get_multichoice;

    /*
      * Function to be used for ux purpose.
      * Get content of list of multichoice,according corresponding i_flg_type
      *
      * @return true if success, false if any unexpected error occured.
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_ds_target
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN NUMBER,
        i_episode      IN NUMBER,
        i_tbl_cmp_orig IN table_number,
        i_action       IN NUMBER,
        o_result       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_action t_big_num;
        k_funtion_value  CONSTANT VARCHAR2(0001 CHAR) := 'F';
        k_flg_type_value CONSTANT VARCHAR2(0001 CHAR) := 'V';
    
    BEGIN
    
        l_id_action := get_default_action();
    
        OPEN o_result FOR
            SELECT t.id_cmpt_mkt_origin,
                   t.id_cmpt_origin,
                   t.id_ds_event,
                   CASE t.flg_type
                       WHEN k_funtion_value THEN
                        k_flg_type_value
                       ELSE
                        t.flg_type
                   END flg_type,
                   CASE t.flg_type
                       WHEN k_funtion_value THEN
                        (SELECT pk_dyn_form_values.get_event_value(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_patient => i_patient,
                                                                   i_episode => i_episode,
                                                                   i_value   => t.value)
                           FROM dual)
                       ELSE
                        t.value
                   END VALUE,
                   t.id_cmpt_mkt_dest,
                   t.id_cmpt_dest,
                   t.field_mask,
                   t.flg_event_target_type,
                   pk_message.get_message(i_lang, t.code_validation_message) validation_message,
                   rn
              FROM (SELECT de.id_ds_cmpt_mkt_rel       id_cmpt_mkt_origin,
                           dcmo.id_ds_component_child  id_cmpt_origin,
                           de.id_action,
                           de.id_ds_event              id_ds_event,
                           de.flg_type                 flg_type,
                           de.value                    VALUE,
                           det.id_ds_cmpt_mkt_rel      id_cmpt_mkt_dest,
                           dcmd.id_ds_component_child  id_cmpt_dest,
                           det.field_mask              field_mask,
                           det.flg_event_type          flg_event_target_type,
                           det.code_validation_message code_validation_message,
                           -- t.id_ds_event, t.id_ds_cmpt_mkt_rel, d.id_action, t.flg_event_type
                           --row_number() over(PARTITION BY de.id_ds_cmpt_mkt_rel, de.id_ds_event, det.id_ds_cmpt_mkt_rel ORDER BY(CASE
                           row_number() over(PARTITION BY de.id_ds_event, det.id_ds_cmpt_mkt_rel, de.id_action, det.flg_event_type ORDER BY(CASE
                               WHEN de.id_action IS NULL THEN
                                -100
                               WHEN de.id_action =
                                    l_id_action THEN
                                -50
                               ELSE
                                de.id_action
                           END) DESC) rn
                      FROM v_ds_event de
                      LEFT JOIN v_ds_event_target det
                        ON det.id_ds_event = de.id_ds_event
                      JOIN (SELECT /*+ OPT_ESTIMATE(TABLE t1 ROWS=1) */
                            column_value id_cmpt_origin
                             FROM TABLE(i_tbl_cmp_orig) t1) xsql
                        ON xsql.id_cmpt_origin = de.id_ds_cmpt_mkt_rel
                      JOIN v_ds_cmpt_mkt_rel dcmo
                        ON dcmo.id_ds_cmpt_mkt_rel = xsql.id_cmpt_origin
                      LEFT JOIN v_ds_cmpt_mkt_rel dcmd
                        ON dcmd.id_ds_cmpt_mkt_rel = det.id_ds_cmpt_mkt_rel
                     WHERE (de.id_action = i_action OR id_action IS NULL OR id_action = l_id_action)) t
             WHERE t.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang => i_lang, i_err_text => SQLERRM, i_function => 'GET_DS_TARGET', o_error => o_error);
        
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
    END get_ds_target;

    --*******************************************
    -- * validated
    FUNCTION get_id_tbl_comp(i_tbl_dyn_cfg IN t_dyn_tree_table) RETURN table_number IS
        tbl_id_cmpt table_number;
    BEGIN
    
        SELECT DISTINCT tt.id_ds_cmpt_mkt_rel
          BULK COLLECT
          INTO tbl_id_cmpt
          FROM TABLE(i_tbl_dyn_cfg) tt;
    
        RETURN tbl_id_cmpt;
    
    END get_id_tbl_comp;

    -- new
    -- * validated
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
        my_error EXCEPTION;
        l_ret01 BOOLEAN;
        l_ret02 BOOLEAN;
    
        l_error   t_big_char;
        tbl_comps table_number := table_number();
        k_func_name CONSTANT t_big_char := 'GET_FULL_ITEMS_BY_NAME';
        tbl_dyn_cfg t_dyn_tree_table := t_dyn_tree_table();
    
        k_action_clinical_questions      NUMBER(24) := 69;
        k_edit_action_clinical_questions NUMBER(24) := 70;
    
        FUNCTION process_local_error(i_sqlerrm IN VARCHAR2) RETURN BOOLEAN IS
        BEGIN
        
            process_error(i_lang => i_lang, i_err_text => i_sqlerrm, i_function => l_error, o_error => o_error);
        
            pk_types.open_my_cursor(o_components);
            pk_types.open_my_cursor(o_ds_target);
            RETURN FALSE;
        
        END process_local_error;
    
    BEGIN
    
        IF i_action IN (k_action_clinical_questions, k_edit_action_clinical_questions)
        THEN
            l_ret01 := pk_mcdt.get_full_items_by_screen(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_patient     => i_patient,
                                                        i_episode     => i_episode,
                                                        i_screen_name => i_component_name,
                                                        i_action      => i_action,
                                                        o_components  => o_components,
                                                        o_ds_target   => o_ds_target,
                                                        o_error       => o_error);
        ELSE
        
            l_error := k_func_name || '-1';
        
            tbl_dyn_cfg := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_patient        => i_patient,
                                                   i_component_name => i_component_name,
                                                   i_action         => i_action);
        
            l_ret01 := get_dyn_items_comp_name(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_action      => i_action,
                                               i_tbl_dyn_cfg => tbl_dyn_cfg,
                                               o_result      => o_components,
                                               o_error       => o_error);
        
            IF NOT l_ret01
            THEN
                RAISE my_error;
            END IF;
        
            l_error   := k_func_name || '-2';
            tbl_comps := get_id_tbl_comp(i_tbl_dyn_cfg => tbl_dyn_cfg);
        
            l_error := k_func_name || '-3';
            l_ret02 := get_ds_target(i_lang         => i_lang,
                                     i_prof         => i_prof,
                                     i_patient      => i_patient,
                                     i_episode      => i_episode,
                                     i_tbl_cmp_orig => tbl_comps,
                                     i_action       => i_action,
                                     o_result       => o_ds_target,
                                     o_error        => o_error);
        
            IF NOT l_ret02
            THEN
                RAISE my_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_error THEN
            RETURN process_local_error(i_sqlerrm => SQLERRM);
        
        WHEN OTHERS THEN
            RETURN process_local_error(i_sqlerrm => SQLERRM);
        
    END get_full_items_by_name;

    -- new
    -- * validated
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
    
        k_action_clinical_questions NUMBER(24) := 69;
        l_id_component              t_big_num;
        l_component_name            t_big_char;
        l_return                    BOOLEAN;
    BEGIN
    
        CASE i_action
            WHEN k_action_clinical_questions THEN
                l_return := pk_mcdt.get_full_items_by_screen(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_patient     => i_patient,
                                                             i_episode     => i_episode,
                                                             i_screen_name => i_screen_name,
                                                             i_action      => i_action,
                                                             o_components  => o_components,
                                                             o_ds_target   => o_ds_target,
                                                             o_error       => o_error);
            ELSE
            
                l_id_component   := get_id_comp_by_screen(i_screen_name);
                l_component_name := get_component_name_by_id(i_id_component => l_id_component);
            
                l_return := get_full_items_by_name(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_patient        => i_patient,
                                                   i_episode        => i_episode,
                                                   i_component_name => l_component_name,
                                                   i_action         => i_action,
                                                   o_components     => o_components,
                                                   o_ds_target      => o_ds_target,
                                                   o_error          => o_error);
        END CASE;
    
        RETURN l_return;
    
    END get_full_items_by_screen;

    /*
      * get unit measure for age processing
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION get_age_mea
    (
        i_age_value    IN NUMBER,
        i_unit_measure IN NUMBER
    ) RETURN NUMBER IS
        l_return t_big_dec;
    BEGIN
    
        CASE i_unit_measure
            WHEN k_id_unit_measure_year THEN
                l_return := i_age_value;
            ELSE
            
                l_return := pk_unit_measure.get_unit_mea_conversion(i_value         => i_age_value,
                                                                    i_unit_meas     => i_unit_measure,
                                                                    i_unit_meas_def => k_id_unit_measure_year);
            
        END CASE;
    
        RETURN l_return;
    
    END get_age_mea;

    -- ************************************************

    /*
      * Base function for age limits processing
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION check_age_limits
    (
        i_pat_age      IN NUMBER,
        i_age_limit    IN NUMBER,
        i_unit_measure IN NUMBER,
        i_limit_type   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_result t_low_char := pk_alert_constant.g_no;
        l_param_error EXCEPTION;
        l_bool            BOOLEAN;
        l_pat_age         t_big_num;
        l_age_limit       t_big_dec;
        l_nvl_value       t_big_num;
        l_id_unit_measure t_big_num;
        k_age_min_value CONSTANT t_big_num := 0;
        k_age_max_value CONSTANT t_big_num := 999999;
    BEGIN
    
        l_pat_age := coalesce(i_pat_age, 0);
    
        l_id_unit_measure := coalesce(i_unit_measure, k_id_unit_measure_year);
    
        l_nvl_value := iif(i_limit_type = k_age_type_limit_min, k_age_min_value, k_age_max_value);
    
        l_age_limit := coalesce(i_age_limit, l_nvl_value);
    
        l_age_limit := get_age_mea(i_age_value => l_age_limit, i_unit_measure => l_id_unit_measure);
    
        CASE i_limit_type
            WHEN k_age_type_limit_min THEN
                l_bool := l_pat_age >= l_age_limit;
            WHEN k_age_type_limit_max THEN
                l_bool := l_pat_age <= l_age_limit;
        END CASE;
    
        IF l_bool
        THEN
            l_result := k_yes;
        END IF;
    
        RETURN l_result;
    
    END check_age_limits;

    /*
      * Check given age with minimum limits
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION check_age_limits_min
    (
        i_pat_age      IN NUMBER,
        i_age_limit    IN NUMBER,
        i_unit_measure IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return t_big_char;
    BEGIN
    
        l_return := check_age_limits(i_pat_age      => i_pat_age,
                                     i_age_limit    => i_age_limit,
                                     i_unit_measure => i_unit_measure,
                                     i_limit_type   => k_age_type_limit_min);
    
        RETURN l_return;
    
    END check_age_limits_min;

    /*
      * Check given age with maximum limits
      *
      * @author Carlos Ferreira
      * @version
      * @since 2019/04
    * -- validated
      */
    FUNCTION check_age_limits_max
    (
        i_pat_age      IN NUMBER,
        i_age_limit    IN NUMBER,
        i_unit_measure IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return t_big_char;
    BEGIN
    
        l_return := check_age_limits(i_pat_age      => i_pat_age,
                                     i_age_limit    => i_age_limit,
                                     i_unit_measure => i_unit_measure,
                                     i_limit_type   => k_age_type_limit_max);
    
        RETURN l_return;
    
    END check_age_limits_max;

    FUNCTION get_multichoice
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_episode              IN NUMBER,
        i_patient              IN NUMBER,
        i_internal_name        IN VARCHAR2,
        i_internal_name_origin IN table_varchar,
        i_internal_name_values IN table_varchar,
        o_result               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_dyn_form_values.get_custom_multichoice(i_lang                 => i_lang,
                                                            i_prof                 => i_prof,
                                                            i_episode              => i_episode,
                                                            i_patient              => i_patient,
                                                            i_root_name            => null,
                                                            i_service_name_curr    => i_internal_name,
                                                            i_internal_name_origin => i_internal_name_origin,
                                                            i_internal_name_values => table_table_varchar(i_internal_name_values),
                                                            o_result               => o_result,
                                                            o_error                => o_error);
    
        RETURN l_bool;
    
    END get_multichoice;

    -- **************************************************
    FUNCTION replace_criteria_sql
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_sql  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_sql VARCHAR2(4000) := i_sql;
    BEGIN
    
        l_sql := REPLACE(l_sql, '@I_LANG', i_lang);
        l_sql := REPLACE(l_sql, '@PROFESSIONAL', i_prof.id);
        l_sql := REPLACE(l_sql, '@INSTITUTION', i_prof.institution);
        l_sql := REPLACE(l_sql, '@SOFTWARE', i_prof.software);
    
        l_sql := pk_dyn_form_constant.get_crit_block_str(i_text => l_sql);
    
        RETURN l_sql;
    
    END replace_criteria_sql;

    -- ************************************************
    FUNCTION process_desc_function
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_desc_func IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_sql    VARCHAR2(4000);
        l_return VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_desc_func IS NOT NULL
        THEN
        
            l_sql := i_desc_func;
        
            l_sql := pk_dyn_form_constant.get_crit_block_str(i_text => l_sql);
        
            l_sql := REPLACE(l_sql, '@I_LANG', i_lang);
            l_sql := REPLACE(l_sql, '@PROFESSIONAL', i_prof.id);
            l_sql := REPLACE(l_sql, '@INSTITUTION', i_prof.institution);
            l_sql := REPLACE(l_sql, '@SOFTWARE', i_prof.software);
        
            EXECUTE IMMEDIATE l_sql
                USING OUT l_return;
        
        END IF;
    
        RETURN l_return;
    
    END process_desc_function;

    -- ***********************************
    FUNCTION get_dyn_descx
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_action    IN NUMBER,
        i_node_type IN VARCHAR2,
        i_tbl_codes IN table_varchar
    ) RETURN VARCHAR2 IS
        l_code   VARCHAR2(1000 CHAR);
        l_return VARCHAR2(4000);
        k_desc_function   CONSTANT NUMBER := 1;
        k_desc_title_add  CONSTANT NUMBER := 4;
        k_desc_title_edit CONSTANT NUMBER := 5;
        k_node_type_root  CONSTANT VARCHAR2(0010 CHAR) := 'R';
        k_hhc_action_add  CONSTANT NUMBER := 235534078;
        k_hhc_action_edit CONSTANT NUMBER := 235534079;
    BEGIN
    
        IF i_node_type = k_node_type_root
        THEN
        
            CASE i_action
                WHEN k_hhc_action_add THEN
                    l_code := i_tbl_codes(k_desc_title_add);
                WHEN k_hhc_action_edit THEN
                    l_code := i_tbl_codes(k_desc_title_edit);
                ELSE
                    l_return := '';
            END CASE;
        
            IF l_code IS NOT NULL
            THEN
                l_return := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code);
            END IF;
        
        ELSE
        
            <<lup_thru_descriptions>>
            FOR i IN 1 .. i_tbl_codes.count
            LOOP
            
                CASE i
                    WHEN k_desc_function THEN
                        l_return := process_desc_function(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_desc_func => i_tbl_codes(k_desc_function));
                    ELSE
                        l_return := pk_message.get_message(i_lang => i_lang, i_code_mess => i_tbl_codes(i));
                END CASE;
            
                IF l_return IS NOT NULL
                THEN
                    EXIT lup_thru_descriptions;
                END IF;
            
            END LOOP lup_thru_descriptions;
        
        END IF;
    
        RETURN l_return;
    
    END get_dyn_descx;

    -- ***********************************
    FUNCTION get_dyn_desc
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_action    IN NUMBER,
        i_node_type IN VARCHAR2,
        i_tbl_codes IN table_varchar
    ) RETURN VARCHAR2 IS
        l_code   VARCHAR2(1000 CHAR);
        l_return VARCHAR2(4000);
        k_desc_function CONSTANT NUMBER := 1;
        --k_alt_desc        CONSTANT NUMBER := 2;
        --k_final_desc      CONSTANT NUMBER := 3;
        k_desc_title_add  CONSTANT NUMBER := 4;
        k_desc_title_edit CONSTANT NUMBER := 5;
        k_node_type_root  CONSTANT VARCHAR2(0010 CHAR) := 'R';
        k_hhc_action_add  CONSTANT NUMBER := 235534078;
        k_hhc_action_edit CONSTANT NUMBER := 235534079;
    BEGIN
    
        IF i_node_type = k_node_type_root
        THEN
        
            CASE i_action
                WHEN k_hhc_action_add THEN
                    l_code := i_tbl_codes(k_desc_title_add);
                WHEN k_hhc_action_edit THEN
                    l_code := i_tbl_codes(k_desc_title_edit);
                ELSE
                    l_code := '';
            END CASE;
        
            l_return := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code);
        
        END IF;
    
        IF l_return IS NULL
        THEN
        
            <<lup_thru_descriptions>>
            FOR i IN 1 .. 3
            LOOP
            
                IF i = k_desc_function
                THEN
                
                    l_return := process_desc_function(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_desc_func => i_tbl_codes(k_desc_function));
                
                ELSE
                
                    l_return := pk_message.get_message(i_lang => i_lang, i_code_mess => i_tbl_codes(i));
                
                END IF;
            
                IF l_return IS NOT NULL
                THEN
                    EXIT lup_thru_descriptions;
                END IF;
            
            END LOOP lup_thru_descriptions;
        
        END IF;
    
        RETURN l_return;
    
    END get_dyn_desc;

    FUNCTION get_id_mkt_rel_dest(i_id_mkt_orig IN table_number) RETURN table_number IS
        tbl_return table_number;
    BEGIN
    
        SELECT id_cmpt_mkt_rel_dest
          BULK COLLECT
          INTO tbl_return
          FROM v_ds_cmpt_mkt_rel_map vm
          JOIN (SELECT /*+ OPT_ESTIMATE(TABLE tbl ROWS=1) */
                 column_value id_row, rownum rn
                  FROM TABLE(i_id_mkt_orig) tbl) xtbl
            ON xtbl.id_row = vm.id_cmpt_mkt_rel_orig
         ORDER BY rn;
    
        RETURN tbl_return;
    
    END get_id_mkt_rel_dest;

    FUNCTION get_id_mkt_rel_dest
    (
        i_lang        IN NUMBER,
        i_id_mkt_orig IN table_number,
        o_result      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_return table_number := table_number();
        l_error    VARCHAR2(4000);
        FUNCTION process_local_error(i_sqlerrm IN VARCHAR2) RETURN BOOLEAN IS
        BEGIN
        
            process_error(i_lang => i_lang, i_err_text => i_sqlerrm, i_function => l_error, o_error => o_error);
        
            pk_types.open_my_cursor(o_result);
            RETURN FALSE;
        
        END process_local_error;
    
    BEGIN
        l_error    := 'Get_id_mkt_rel_dest';
        tbl_return := get_id_mkt_rel_dest(i_id_mkt_orig => i_id_mkt_orig);
    
        l_error := 'o_result fetch';
        OPEN o_result FOR
            SELECT column_value id_mkt_rel_dest
              FROM TABLE(tbl_return);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN process_local_error(i_sqlerrm => SQLERRM);
    END get_id_mkt_rel_dest;

BEGIN

    -- Initializes log context
    pk_alertlog.log_init(object_name => k_pck_name);

END pk_dyn_form;
/
