CREATE OR REPLACE PACKAGE BODY pk_orders_utils IS

    --Funtion to return the value of the selected element in the form (single value)
    FUNCTION get_value
    (
        i_internal_name_child IN VARCHAR2,
        i_tbl_mkt_rel         IN table_number,
        i_value               IN table_table_varchar,
        i_index               IN NUMBER DEFAULT 1
    ) RETURN VARCHAR2 IS
        l_rows table_number;
        l_ret  table_varchar := table_varchar();
    BEGIN
        SELECT t.rn
          BULK COLLECT
          INTO l_rows
          FROM ds_cmpt_mkt_rel d
          JOIN (SELECT column_value, rownum AS rn
                  FROM TABLE(i_tbl_mkt_rel)) t
            ON t.column_value = d.id_ds_cmpt_mkt_rel
         WHERE d.internal_name_child IN (i_internal_name_child);
    
        SELECT /*+opt_estimate (table t rows=1)*/
         t.column_value
          BULK COLLECT
          INTO l_ret
          FROM (SELECT column_value
                  FROM TABLE(i_value(l_rows(1)))) t
         WHERE t.column_value IS NOT NULL;
    
        RETURN l_ret(i_index);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_value;

    FUNCTION get_ds_cmpt_mkt_rel
    (
        i_internal_name IN VARCHAR2,
        i_tbl_mkt_rel   IN table_number
    ) RETURN NUMBER IS
        l_ret ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
    BEGIN
        SELECT d.id_ds_cmpt_mkt_rel
          INTO l_ret
          FROM ds_cmpt_mkt_rel d
          JOIN (SELECT column_value, rownum AS rn
                  FROM TABLE(i_tbl_mkt_rel)) t
            ON t.column_value = d.id_ds_cmpt_mkt_rel
         WHERE d.internal_name_child = i_internal_name;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ds_cmpt_mkt_rel;

    FUNCTION get_ds_internal_name(i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN VARCHAR IS
        l_ret ds_cmpt_mkt_rel.internal_name_child%TYPE;
    BEGIN
    
        SELECT dc.internal_name_child
          INTO l_ret
          FROM ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_cmpt_mkt_rel = i_id_ds_cmpt_mkt_rel;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ds_internal_name;

    FUNCTION get_id_ds_component(i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN NUMBER IS
        l_ret ds_cmpt_mkt_rel.id_ds_component_child%TYPE;
    BEGIN
    
        SELECT dc.id_ds_component_child
          INTO l_ret
          FROM ds_cmpt_mkt_rel dc
         WHERE dc.id_ds_cmpt_mkt_rel = i_id_ds_cmpt_mkt_rel;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_ds_component;

    FUNCTION get_rehab_session_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_rehab_session_type rehab_session_type.id_rehab_session_type%TYPE;
    
    BEGIN
    
        SELECT t.id_rehab_session_type
          INTO l_rehab_session_type
          FROM (SELECT id_rehab_session_type,
                       row_number() over(PARTITION BY id_rehab_area_interv ORDER BY id_institution DESC, id_software DESC) AS rn
                  FROM rehab_inst_soft ris
                 WHERE ris.id_institution IN (0, i_prof.institution)
                   AND ris.id_software IN (0, i_prof.software)
                   AND ris.flg_add_remove = 'A'
                   AND ris.id_rehab_area_interv = i_rehab_area_interv
                   AND ris.id_rehab_area_interv NOT IN (SELECT id_rehab_area_interv
                                                          FROM rehab_inst_soft
                                                         WHERE id_institution IN (0, i_prof.institution)
                                                           AND id_software IN (0, i_prof.software)
                                                           AND flg_add_remove = 'R')) t
         WHERE t.rn = 1;
    
        RETURN l_rehab_session_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_rehab_session_type;

    FUNCTION get_p1_id_detail
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_episode             IN NUMBER,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_type            IN p1_detail.flg_type%TYPE
    ) RETURN NUMBER IS
        l_ret p1_detail.id_detail%TYPE := NULL;
    BEGIN
    
        IF i_id_external_request IS NOT NULL
        THEN
            SELECT t.id_detail id
              INTO l_ret
              FROM (SELECT pd.id_detail
                      FROM p1_detail pd
                     WHERE pd.id_external_request = i_id_external_request
                       AND pd.flg_type = i_flg_type
                       AND pd.flg_status = pk_alert_constant.g_active
                     ORDER BY pd.dt_insert_tstz DESC, pd.flg_status) t
             WHERE rownum = 1;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_p1_id_detail;

    FUNCTION get_bp_default_values
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_episode     IN NUMBER,
        i_patient     IN NUMBER,
        i_tbl_id_pk   IN table_number,
        i_tbl_mkt_rel IN table_number,
        io_tbl_result IN OUT t_tbl_ds_get_value
    ) RETURN BOOLEAN IS
        l_epis_type             epis_type.id_epis_type%TYPE;
        l_value_to_execute      VARCHAR2(4000);
        l_value_to_execute_desc VARCHAR2(4000);
        l_flg_time              sys_config.value%TYPE;
    
        l_desc_unit_measure VARCHAR2(1000);
    
        l_ds_internal_name ds_component.internal_name%TYPE;
        l_id_ds_component  ds_component.id_ds_component%TYPE;
    
    BEGIN
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_to_execute_list
            THEN
                SELECT e.id_epis_type
                  INTO l_epis_type
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            
                l_flg_time := pk_sysconfig.get_config('FLG_TIME_E', i_prof.institution, i_prof.software);
            
                SELECT data, label
                  INTO l_value_to_execute, l_value_to_execute_desc
                  FROM (SELECT data, label, flg_default
                          FROM (SELECT /*+opt_estimate(table s rows=1)*/
                                 val data,
                                 desc_val label,
                                 decode(l_flg_time,
                                        val,
                                        pk_blood_products_constant.g_yes,
                                        pk_blood_products_constant.g_no) flg_default
                                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                                      decode(l_epis_type,
                                                                                             NULL,
                                                                                             i_prof,
                                                                                             profissional(i_prof.id,
                                                                                                          i_prof.institution,
                                                                                                          i_prof.software)),
                                                                                      'BLOOD_PRODUCT_REQ.FLG_TIME',
                                                                                      NULL)) s)
                         WHERE flg_default = pk_alert_constant.g_yes)
                 WHERE rownum = 1;
            
                io_tbl_result.extend();
                io_tbl_result(io_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                         id_ds_component    => l_id_ds_component,
                                                                         internal_name      => l_ds_internal_name,
                                                                         VALUE              => l_value_to_execute,
                                                                         value_clob         => NULL,
                                                                         min_value          => NULL,
                                                                         max_value          => NULL,
                                                                         desc_value         => l_value_to_execute_desc,
                                                                         desc_clob          => NULL,
                                                                         id_unit_measure    => NULL,
                                                                         desc_unit_measure  => NULL,
                                                                         flg_validation     => NULL,
                                                                         err_msg            => NULL,
                                                                         flg_event_type     => NULL,
                                                                         flg_multi_status   => NULL,
                                                                         idx                => 1);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_quantity_execution
            THEN
            
                l_desc_unit_measure := pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                    i_prof         => i_prof,
                                                                                    i_unit_measure => 10610); --Bag(s)
            
                io_tbl_result.extend();
                io_tbl_result(io_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                         id_ds_component    => l_id_ds_component,
                                                                         internal_name      => l_ds_internal_name,
                                                                         VALUE              => to_char(1),
                                                                         value_clob         => NULL,
                                                                         min_value          => NULL,
                                                                         max_value          => NULL,
                                                                         desc_value         => 1 || ' ' ||
                                                                                               l_desc_unit_measure, --Bag(s)
                                                                         desc_clob          => NULL,
                                                                         id_unit_measure    => 10610,
                                                                         desc_unit_measure  => l_desc_unit_measure,
                                                                         flg_validation     => NULL,
                                                                         err_msg            => NULL,
                                                                         flg_event_type     => NULL,
                                                                         flg_multi_status   => NULL,
                                                                         idx                => 1);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_hemo_type
            THEN
                --This value must be stored to get the list of special instructions and special type,
                --because those lists depend on the selected bag
                io_tbl_result.extend();
                io_tbl_result(io_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                         id_ds_component    => l_id_ds_component,
                                                                         internal_name      => l_ds_internal_name,
                                                                         VALUE              => to_char(i_tbl_id_pk(1)),
                                                                         value_clob         => NULL,
                                                                         min_value          => NULL,
                                                                         max_value          => NULL,
                                                                         desc_value         => to_char(i_tbl_id_pk(1)),
                                                                         desc_clob          => NULL,
                                                                         id_unit_measure    => NULL,
                                                                         desc_unit_measure  => NULL,
                                                                         flg_validation     => NULL,
                                                                         err_msg            => NULL,
                                                                         flg_event_type     => NULL,
                                                                         flg_multi_status   => NULL,
                                                                         idx                => 1);
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_bp_default_values;

    FUNCTION get_bp_submit_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_tbl_id_pk      IN table_number,
        i_curr_component IN NUMBER,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        io_tbl_result    IN OUT t_tbl_ds_get_value
    ) RETURN BOOLEAN IS
        l_hemo_type_count    PLS_INTEGER;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        l_aux_table t_tbl_ds_get_value := t_tbl_ds_get_value();
    BEGIN
    
        l_hemo_type_count    := i_tbl_id_pk.count();
        l_curr_comp_int_name := get_ds_internal_name(i_curr_component);
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name IN
               (pk_orders_constant.g_ds_special_instructions, pk_orders_constant.g_ds_special_type)
               AND l_curr_comp_int_name = pk_orders_constant.g_ds_priority
            THEN
                l_aux_table := t_tbl_ds_get_value();
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                           id_ds_component    => l_id_ds_component,
                                           internal_name      => l_ds_internal_name,
                                           VALUE              => NULL,
                                           value_clob         => NULL,
                                           min_value          => NULL,
                                           max_value          => NULL,
                                           desc_value         => NULL,
                                           desc_clob          => NULL,
                                           id_unit_measure    => NULL,
                                           desc_unit_measure  => NULL,
                                           flg_validation     => pk_alert_constant.g_yes,
                                           err_msg            => CASE
                                                                     WHEN l_hemo_type_count > 1 THEN
                                                                     --  'Only one bag can be selected for editing the special type fields'
                                                                      pk_message.get_message(i_lang, t.code_validation_msg)
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                           flg_event_type     => CASE
                                                                     WHEN l_hemo_type_count > 1 THEN
                                                                      pk_alert_constant.g_inactive
                                                                 END,
                                           flg_multi_status   => NULL,
                                           idx                => 1)
                  BULK COLLECT
                  INTO l_aux_table
                  FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                               dc.id_ds_component_child,
                               dc.internal_name_child,
                               dc.flg_event_type,
                               dc.rn,
                               dc.flg_component_type_child,
                               dc.id_unit_measure,
                               dc.code_validation_msg
                          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => NULL,
                                                             i_component_name => 'DS_BLOOD_PRODUCTS',
                                                             i_action         => NULL)) dc) t
                  JOIN ds_component d
                    ON d.id_ds_component = t.id_ds_component_child
                 WHERE d.internal_name = l_ds_internal_name;
            
                FOR i IN l_aux_table.first .. l_aux_table.last
                LOOP
                    io_tbl_result.extend();
                    io_tbl_result(io_tbl_result.count) := l_aux_table(i);
                END LOOP;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_bp_submit_values;

    FUNCTION get_ok_button_control
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_tbl_result     IN OUT t_tbl_ds_get_value,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ok_status VARCHAR2(1) := pk_orders_constant.g_component_valid;
    
        l_id_ds_cmpt_mkt_rel_ok ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        l_id_ds_component_ok    ds_component.id_ds_component%TYPE;
        l_ds_internal_name_ok   ds_component.internal_name%TYPE;
    
        l_tbl_configured_items   table_varchar := table_varchar();
        l_tbl_id_ds_cmpt_mkt_rel table_number;
    
        l_value_aux VARCHAR2(4000 CHAR);
    
        l_sys_config_value sys_config.value%TYPE;
    
        l_co_sign_available VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        --List of components that may be mandatory (i.e. depending of a configuration, of values of the form, etc.)
        l_tbl_possible_mandatory_items table_varchar := table_varchar(pk_orders_constant.g_ds_clinical_purpose,
                                                                      pk_orders_constant.g_ds_clinical_purpose_ft,
                                                                      pk_orders_constant.g_ds_laterality,
                                                                      pk_orders_constant.g_ds_to_execute_list,
                                                                      pk_orders_constant.g_ds_other_frequency,
                                                                      pk_orders_constant.g_ds_start_date,
                                                                      pk_orders_constant.g_ds_place_service,
                                                                      pk_orders_constant.g_ds_order_type,
                                                                      pk_orders_constant.g_ds_ordered_by,
                                                                      pk_orders_constant.g_ds_ordered_at);
    
    BEGIN
    
        --Verifiy if the component 'DS_OK_BUTTON_CONTROL' is configured in the form
        --If it isn't, the verification of the form integrity will not be performed.
        g_error := 'VERIFYING DS_OK_BUTTON_CONTROL PRESENCE IN THE FORM';
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            IF i_tbl_int_name(i) = pk_orders_constant.g_ds_ok_button_control
            THEN
                l_ds_internal_name_ok   := i_tbl_int_name(i);
                l_id_ds_component_ok    := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                l_id_ds_cmpt_mkt_rel_ok := i_tbl_mkt_rel(i);
                EXIT;
            END IF;
        END LOOP;
    
        --Component 'DS_OK_BUTTON_CONTROL' has been found, therefore, we will verify if there are mandatory fields,
        --and, for those fields, we will verify if they are null.    
        IF l_ds_internal_name_ok IS NOT NULL
        THEN
            --First we verify if the form is loaded from an edition
            --When editing, if the user has not yet perform any change, the OK button cannot be available
            IF i_action IN (pk_orders_constant.g_action_edition)
            THEN
                l_ok_status := pk_orders_constant.g_component_error;
            END IF;
        
            --Then we analyse the structure i_tbl_result that was sent to us when calling the current function.
            --This structure already indicates if a component is mandatory, and it also indicates its possible value.
            --If there is a mandatory element with no value, we can assure that the form is invalid, and no further
            --verification is needed, so we can stop the verification.
            --Note: i_tbl_result may not present all the elements of a given form, therefore, if no empty mandatory field has been found,
            --it may still be necessary to analyze the remaining fields of the form.
            IF l_ok_status = pk_orders_constant.g_component_valid
            THEN
                g_error := 'ANALYZING I_TBL_RESULT FOR MANDATORY COMPONENTS';
                IF i_tbl_result.count > 0
                THEN
                    FOR i IN i_tbl_result.first .. i_tbl_result.last
                    LOOP
                        IF (i_tbl_result(i).flg_event_type = pk_orders_constant.g_component_mandatory AND i_tbl_result(i).value IS NULL)
                           OR i_tbl_result(i).flg_validation = pk_orders_constant.g_component_error
                        THEN
                            l_ok_status := pk_orders_constant.g_component_error;
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        
            --No integrity problem has yet been found, but it may still be necessary to analyze the remaining fields.
            IF l_ok_status = pk_orders_constant.g_component_valid
            THEN
                --Check which possible mandatory items (defined in l_tbl_possible_mandatory_items) are available on the form
                --We perform a left join with i_tbl_result to assure that we will not again analyze the components
                --that were analyzed in the previous step.
                g_error := 'FETCHING L_TBL_CONFIGURED_ITEMS';
                SELECT dc.internal_name_child, dc.id_ds_cmpt_mkt_rel
                  BULK COLLECT
                  INTO l_tbl_configured_items, l_tbl_id_ds_cmpt_mkt_rel
                  FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_patient        => NULL,
                                                     i_component_name => i_root_name,
                                                     i_action         => NULL)) dc
                  JOIN (SELECT /*+opt_estimate(table m rows=1)*/
                         m.*
                          FROM TABLE(l_tbl_possible_mandatory_items) m) t
                    ON t.column_value = dc.internal_name_child
                  LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                              t.*
                               FROM TABLE(i_tbl_result) t) tt
                    ON tt.id_ds_cmpt_mkt_rel = dc.id_ds_cmpt_mkt_rel
                 WHERE tt.id_ds_cmpt_mkt_rel IS NULL;
            
                --If one of the mandatory fields is empty, there is no need to continue the cicle.
                g_error := 'CYCLING THROUGH L_TBL_CONFIGURED_ITEMS';
                IF l_tbl_configured_items.exists(1)
                THEN
                    FOR i IN l_tbl_configured_items.first .. l_tbl_configured_items.last
                    LOOP
                        IF l_tbl_configured_items(i) IN
                           (pk_orders_constant.g_ds_to_execute_list, pk_orders_constant.g_ds_place_service)
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF l_tbl_id_ds_cmpt_mkt_rel(i) = i_tbl_mkt_rel(j)
                                THEN
                                    IF i_value(j) (1) IS NULL
                                    THEN
                                        l_ok_status := pk_orders_constant.g_component_error;
                                        EXIT;
                                    END IF;
                                END IF;
                            END LOOP;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_start_date
                        THEN
                            FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                            LOOP
                                IF i_tbl_int_name(j) = pk_orders_constant.g_ds_flg_time
                                THEN
                                    l_value_aux := i_value(j) (1);
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            IF l_value_aux IS NULL
                               OR l_value_aux NOT IN (pk_alert_constant.g_flg_time_b, pk_alert_constant.g_flg_time_n)
                            THEN
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    IF l_tbl_id_ds_cmpt_mkt_rel(i) = i_tbl_mkt_rel(j)
                                    THEN
                                        IF i_value(j) (1) IS NULL
                                        THEN
                                            l_ok_status := pk_orders_constant.g_component_error;
                                            EXIT;
                                        END IF;
                                    END IF;
                                END LOOP;
                            END IF;
                        ELSIF l_tbl_configured_items(i) IN
                              (pk_orders_constant.g_ds_clinical_purpose, pk_orders_constant.g_ds_laterality)
                        THEN
                            IF i_root_name = pk_orders_constant.g_ds_procedure_request
                            THEN
                                l_sys_config_value := CASE l_tbl_configured_items(i)
                                                          WHEN pk_orders_constant.g_ds_clinical_purpose THEN
                                                           pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_P',
                                                                                   i_prof)
                                                          WHEN pk_orders_constant.g_ds_laterality THEN
                                                           pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY',
                                                                                   i_prof)
                                                      END;
                            
                                IF l_sys_config_value = pk_alert_constant.g_yes
                                THEN
                                    FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                    LOOP
                                        IF l_tbl_id_ds_cmpt_mkt_rel(i) = i_tbl_mkt_rel(j)
                                        THEN
                                            IF i_value(j) (1) IS NULL
                                            THEN
                                                l_ok_status := pk_orders_constant.g_component_error;
                                                EXIT;
                                            END IF;
                                        END IF;
                                    END LOOP;
                                END IF;
                            END IF;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_clinical_purpose_ft
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j)) =
                                   pk_orders_constant.g_ds_clinical_purpose
                                THEN
                                    l_value_aux := i_value(j) (1);
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            --Other clinical purpose  
                            IF l_value_aux = '0'
                            THEN
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    IF l_tbl_id_ds_cmpt_mkt_rel(i) = i_tbl_mkt_rel(j)
                                    THEN
                                        IF i_value(j) (1) IS NULL
                                        THEN
                                            l_ok_status := pk_orders_constant.g_component_error;
                                            EXIT;
                                        END IF;
                                    END IF;
                                END LOOP;
                            END IF;
                        ELSIF l_tbl_configured_items(i) = pk_orders_constant.g_ds_other_frequency
                        THEN
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF pk_orders_utils.get_ds_internal_name(i_tbl_mkt_rel(j)) =
                                   pk_orders_constant.g_ds_frequency
                                THEN
                                    l_value_aux := i_value(j) (1);
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            --OTHER FREQUENCY
                            IF l_value_aux = '-1'
                            THEN
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    IF l_tbl_id_ds_cmpt_mkt_rel(i) = i_tbl_mkt_rel(j)
                                    THEN
                                        IF i_value(j) (1) IS NULL
                                        THEN
                                            l_ok_status := pk_orders_constant.g_component_error;
                                            EXIT;
                                        END IF;
                                    END IF;
                                END LOOP;
                            END IF;
                        ELSIF l_tbl_configured_items(i) IN
                              (pk_orders_constant.g_ds_order_type,
                               pk_orders_constant.g_ds_ordered_by,
                               pk_orders_constant.g_ds_ordered_at)
                        THEN
                            g_error := 'ERROR CALLING PK_CO_SIGN_UX.CHECK_PROF_NEEDS_COSIGN_ORDER';
                            IF NOT pk_co_sign_ux.check_prof_needs_cosign_order(i_lang                 => i_lang,
                                                                               i_prof                 => i_prof,
                                                                               i_episode              => i_episode,
                                                                               i_task_type            => CASE i_root_name
                                                                                                             WHEN
                                                                                                              pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                              11
                                                                                                             WHEN
                                                                                                              pk_orders_constant.g_ds_procedure_request THEN
                                                                                                              43
                                                                                                             WHEN
                                                                                                              pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                              7
                                                                                                             WHEN
                                                                                                              pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                              8
                                                                                                         END,
                                                                               o_flg_prof_need_cosign => l_co_sign_available,
                                                                               o_error                => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            IF l_co_sign_available = pk_alert_constant.g_yes
                            THEN
                                FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                LOOP
                                    IF i_tbl_mkt_rel(i) = i_tbl_mkt_rel(j)
                                       AND i_value(j) (1) IS NULL
                                    THEN
                                        l_ok_status := pk_orders_constant.g_component_error;
                                        EXIT;
                                    END IF;
                                END LOOP;
                            END IF;
                        END IF;
                    
                        IF l_ok_status = pk_orders_constant.g_component_error
                        THEN
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        
            --Push the DS_OK_BUTTON_CONTROL element to the i_tbl_result structure, stating if the form is or isn't valid (l_ok_status)
            g_error := 'PUSHING I_TBL_RESULT';
            i_tbl_result.extend();
            i_tbl_result(i_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => l_id_ds_cmpt_mkt_rel_ok,
                                                                   id_ds_component    => l_id_ds_component_ok,
                                                                   internal_name      => l_ds_internal_name_ok,
                                                                   VALUE              => NULL,
                                                                   value_clob         => NULL,
                                                                   min_value          => NULL,
                                                                   max_value          => NULL,
                                                                   desc_value         => NULL,
                                                                   desc_clob          => NULL,
                                                                   id_unit_measure    => NULL,
                                                                   desc_unit_measure  => NULL,
                                                                   flg_validation     => l_ok_status,
                                                                   err_msg            => NULL,
                                                                   flg_event_type     => pk_orders_constant.g_component_active,
                                                                   flg_multi_status   => NULL,
                                                                   idx                => i_idx);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OK_BUTTON_CONTROL',
                                              o_error);
            RETURN FALSE;
    END get_ok_button_control;

    FUNCTION get_other_frequencies_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_data       IN table_table_varchar,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_value_mea      IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        /*#########################################################################################################################
        i_tbl_id_pk   => Holds each one of the id_order_recurrence_plan of the records selected in the viewer
        i_tbl_data(1) => Holds the root name of the form that called the 'Other frequencies' modal window.
        ###########################################################################################################################*/
    
        l_tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
    
        l_tbl_edit_field_name table_varchar;
    
        --RECURRENCE
        l_occurrences        order_recurr_plan.occurrences%TYPE;
        l_duration           order_recurr_plan.duration%TYPE;
        l_unit_meas_duration order_recurr_plan.id_unit_meas_duration%TYPE;
    
        --RECURRENC OTHER        
        l_regular_interval      order_recurr_plan.regular_interval%TYPE;
        l_regular_interval_desc VARCHAR2(500);
        l_regulat_interval_um   NUMBER(24);
        l_daily_executions      order_recurr_plan.daily_executions%TYPE; -- NUMBER(24);
    
        l_tbl_order_recurr_plan      table_number := table_number();
        l_tbl_regular_interval       table_number;
        l_tbl_unit_meas_reg_interval table_number;
        l_tbl_daily_executions       table_number;
        l_tbl_tbl_predef_time_sched  table_table_number;
        l_tbl_predef_time_sched      table_number;
        l_predef_time_sched_desc     VARCHAR2(500);
        l_predef_time_sched          NUMBER(24);
        l_exec_times                 pk_types.cursor_type;
        l_tbl_exec_times_desc        table_varchar := table_varchar();
        l_tbl_exec_times             table_varchar := table_varchar();
        l_tbl_exec_times_aux         table_varchar := table_varchar();
        l_exec_time                  VARCHAR2(500);
        l_exec_time_desc             VARCHAR2(500);
        l_exec_time_option           NUMBER(24);
    
        l_tbl_exec_time_parsed table_varchar := table_varchar();
    
        l_tbl_flg_recurr_pattern     table_varchar;
        l_recurr_pattern_desc        VARCHAR2(500);
        l_tbl_repeat_every           table_number;
        l_tbl_unit_meas_repeat_every table_number;
        l_repeat_every_desc          VARCHAR2(500);
        l_tbl_flg_repeat_by          table_varchar;
        l_repeat_by_desc             VARCHAR2(500);
        l_tbl_start_date             table_varchar;
        l_start_date_str             VARCHAR2(500);
        l_start_date_desc            VARCHAR2(500);
        l_tbl_flg_end_by             table_varchar;
        l_end_date_str               VARCHAR2(500);
        l_end_by_desc                VARCHAR2(500);
        l_tbl_occurrences            table_number;
        l_tbl_duration               table_number;
        l_tbl_unit_meas_duration     table_number;
        l_tbl_end_date               table_varchar;
        l_end_after_desc             VARCHAR2(500);
        l_end_after_um               NUMBER(24);
        l_tbl_tbl_flg_week_day       table_table_number;
        l_tbl_flg_week_day           table_number;
        l_week_day_desc              VARCHAR2(500);
        l_tbl_tbl_flg_week           table_table_number;
        l_tbl_flg_week               table_number;
        l_week_desc                  VARCHAR2(500);
        l_tbl_tbl_month_day          table_table_number;
        l_tbl_month_day              table_number;
        l_tbl_tbl_month              table_table_number;
        l_tbl_month                  table_number;
        l_month_desc                 VARCHAR2(500);
        l_flg_regular_interval_edit  VARCHAR2(500);
        l_flg_daily_executions_edit  VARCHAR2(500);
        l_flg_predef_time_sched_edit VARCHAR2(500);
        l_flg_exec_time_edit         VARCHAR2(500);
        l_flg_repeat_every_edit      VARCHAR2(500);
        l_flg_repeat_by_edit         VARCHAR2(500);
        l_flg_start_date_edit        VARCHAR2(500);
        l_flg_end_by_edit            VARCHAR2(500);
        l_flg_end_after_edit         VARCHAR2(500);
        l_flg_week_day_edit          VARCHAR2(500);
        l_flg_week_edit              VARCHAR2(500);
        l_flg_month_day_edit         VARCHAR2(500);
        l_flg_month_edit             VARCHAR2(500);
        l_flg_ok_avail               VARCHAR2(500);
    
        l_start VARCHAR2(500);
        l_end   VARCHAR2(500);
    
        l_unit_meas_regular_interval order_recurr_plan.id_unit_meas_regular_interval%TYPE;
        l_flg_recurr_pattern         order_recurr_plan.flg_recurr_pattern%TYPE;
        l_repeat_every               order_recurr_plan.repeat_every%TYPE;
        l_unit_meas_repeat_every     unit_measure.id_unit_measure%TYPE;
        l_flg_repeat_by              order_recurr_plan.flg_repeat_by%TYPE;
        l_flg_end_by                 order_recurr_plan.flg_end_by%TYPE;
    
        l_end_based_unique VARCHAR2(1) := pk_alert_constant.g_yes;
    
        l_predef_time_sched_status VARCHAR2(1 CHAR) := pk_orders_constant.g_component_inactive;
    
        l_flg_end_date VARCHAR2(1 CHAR);
    
        l_tbl_number_aux  table_number := table_number();
        l_tbl_varchar_aux table_varchar := table_varchar();
    
        l_db_object_name VARCHAR2(100) := 'GET_OTHER_FREQUENCIES_VALUES';
    
        FUNCTION is_end_based_unique RETURN VARCHAR IS
            l_count PLS_INTEGER;
        BEGIN
            SELECT COUNT(1)
              INTO l_count
              FROM (SELECT DISTINCT orp.flg_end_by
                      FROM order_recurr_plan orp
                     WHERE orp.id_order_recurr_plan IN (SELECT t.column_value /*+opt_estimate (table t rows=1)*/
                                                          FROM TABLE(i_tbl_id_pk) t));
        
            IF l_count > 1
            THEN
                RETURN pk_alert_constant.g_no;
            ELSE
                RETURN pk_alert_constant.g_yes;
            END IF;
        END is_end_based_unique;
    
    BEGIN
    
        g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        IF i_action IS NULL
        THEN
            --NEW FORM (default values)        
            IF NOT pk_order_recurrence_api_ux.get_other_order_recurr_option(i_lang                       => i_lang,
                                                                            i_prof                       => i_prof,
                                                                            i_order_recurr_plans         => table_number(i_tbl_id_pk(i_idx)),
                                                                            i_flg_context                => 'P',
                                                                            o_regular_interval           => l_regular_interval,
                                                                            o_unit_meas_regular_interval => l_unit_meas_regular_interval,
                                                                            o_regular_interval_desc      => l_regular_interval_desc,
                                                                            o_daily_executions           => l_daily_executions,
                                                                            o_predef_time_sched          => l_tbl_predef_time_sched,
                                                                            o_predef_time_sched_desc     => l_predef_time_sched_desc,
                                                                            o_exec_times                 => l_exec_times,
                                                                            o_flg_recurr_pattern         => l_flg_recurr_pattern,
                                                                            o_recurr_pattern_desc        => l_recurr_pattern_desc,
                                                                            o_repeat_every               => l_repeat_every,
                                                                            o_unit_meas_repeat_every     => l_unit_meas_repeat_every,
                                                                            o_repeat_every_desc          => l_repeat_every_desc,
                                                                            o_flg_repeat_by              => l_flg_repeat_by,
                                                                            o_repeat_by_desc             => l_repeat_by_desc,
                                                                            o_start_date                 => l_start, --l_start_date,---
                                                                            o_flg_end_by                 => l_flg_end_by,
                                                                            o_end_by_desc                => l_end_by_desc,
                                                                            o_occurrences                => l_occurrences,
                                                                            o_duration                   => l_duration,
                                                                            o_unit_meas_duration         => l_unit_meas_duration,
                                                                            o_end_date                   => l_end, --l_end_date,
                                                                            o_end_after_desc             => l_end_after_desc,
                                                                            o_flg_week_day               => l_tbl_flg_week_day,
                                                                            o_week_day_desc              => l_week_day_desc,
                                                                            o_flg_week                   => l_tbl_flg_week,
                                                                            o_week_desc                  => l_week_desc,
                                                                            o_month_day                  => l_tbl_month_day,
                                                                            o_month                      => l_tbl_month,
                                                                            o_month_desc                 => l_month_desc,
                                                                            o_flg_regular_interval_edit  => l_flg_regular_interval_edit,
                                                                            o_flg_daily_executions_edit  => l_flg_daily_executions_edit,
                                                                            o_flg_predef_time_sched_edit => l_flg_predef_time_sched_edit,
                                                                            o_flg_exec_time_edit         => l_flg_exec_time_edit,
                                                                            o_flg_repeat_every_edit      => l_flg_repeat_every_edit,
                                                                            o_flg_repeat_by_edit         => l_flg_repeat_by_edit,
                                                                            o_flg_start_date_edit        => l_flg_start_date_edit,
                                                                            o_flg_end_by_edit            => l_flg_end_by_edit,
                                                                            o_flg_end_after_edit         => l_flg_end_after_edit,
                                                                            o_flg_week_day_edit          => l_flg_week_day_edit,
                                                                            o_flg_week_edit              => l_flg_week_edit,
                                                                            o_flg_month_day_edit         => l_flg_month_day_edit,
                                                                            o_flg_month_edit             => l_flg_month_edit,
                                                                            o_flg_ok_avail               => l_flg_ok_avail,
                                                                            o_error                      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            --Obtaining the 'Predefined time schedule' and the 'Exact time' information
            DECLARE
                l_exec_time_parent_option NUMBER(24);
                l_exec_time_option_aux    NUMBER(24);
                l_exec_time_aux           VARCHAR2(1000 CHAR);
                l_exec_time_desc_aux      VARCHAR2(1000 CHAR);
            
                l_count PLS_INTEGER := 0;
            BEGIN
                LOOP
                    FETCH l_exec_times
                        INTO l_exec_time_parent_option, l_exec_time_option_aux, l_exec_time_aux, l_exec_time_desc_aux;
                    EXIT WHEN l_exec_times%NOTFOUND;
                
                    l_count := l_count + 1;
                
                    l_tbl_exec_times_desc.extend();
                    l_tbl_exec_times_desc(l_tbl_exec_times_desc.count) := l_exec_time_desc_aux;
                
                    l_tbl_exec_times.extend();
                    l_tbl_exec_times(l_tbl_exec_times.count) := l_exec_time_aux;
                
                    IF l_count = 1
                    THEN
                        l_exec_time_option := l_exec_time_option_aux;
                    END IF;
                END LOOP;
            
                FOR i IN 1 .. 9
                LOOP
                    IF l_tbl_exec_times.exists(i)
                    THEN
                        l_tbl_exec_time_parsed.extend();
                        l_tbl_exec_time_parsed(l_tbl_exec_time_parsed.count) := '00000101' ||
                                                                                to_char(l_tbl_exec_times(i)) || '00';
                    ELSE
                        l_tbl_exec_time_parsed.extend();
                        l_tbl_exec_time_parsed(l_tbl_exec_time_parsed.count) := NULL;
                    END IF;
                END LOOP;
            END;
        
            --Obtaining the 'Regular intervals' information
            --This is a fix, since the api pk_order_recurrence_api_ux.get_other_order_recurr_option does not return the correct value
            BEGIN
                SELECT orp.regular_interval, orp.id_unit_meas_regular_interval
                  INTO l_regular_interval, l_regulat_interval_um
                  FROM order_recurr_plan orp
                 WHERE orp.id_order_recurr_plan = i_tbl_id_pk(i_idx);
            EXCEPTION
                WHEN OTHERS THEN
                    l_regular_interval := NULL;
            END;
        
            --Check if the field 'Predefined time schedule' has to be active
            --It will only be active if the pk_order_recurrence_core.get_predefined_time_schedules returns results        
            SELECT /*+opt_estimate(table t rows=1)*/
             decode(COUNT(1), 0, pk_orders_constant.g_component_inactive, pk_orders_constant.g_component_active)
              INTO l_predef_time_sched_status
              FROM TABLE(pk_order_recurrence_core.get_predefined_time_schedules(i_lang              => i_lang,
                                                                                i_prof              => i_prof,
                                                                                i_order_recurr_area => CASE
                                                                                                        i_tbl_data(i_idx) (1)
                                                                                                           WHEN
                                                                                                            'DS_BLOOD_PRODUCTS' THEN
                                                                                                            'BLOOD_PRODUCTS'
                                                                                                           WHEN
                                                                                                            pk_orders_constant.g_ds_health_education_order THEN
                                                                                                            'PATIENT_EDUCATION'
                                                                                                           WHEN
                                                                                                            pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                            'LAB_TEST'
                                                                                                           WHEN
                                                                                                            pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                            'IMAGE_EXAM'
                                                                                                           WHEN
                                                                                                            pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                            'OTHER_EXAM'
                                                                                                           WHEN
                                                                                                            pk_orders_constant.g_ds_procedure_request THEN
                                                                                                            'PROCEDURE'
                                                                                                           WHEN
                                                                                                            pk_orders_constant.g_ds_health_education_order THEN
                                                                                                            'PATIENT_EDUCATION'
                                                                                                           WHEN
                                                                                                            pk_orders_constant.g_ds_order_set_procedure THEN
                                                                                                            'PROCEDURE'
                                                                                                       END)) t;
        
            l_end_based_unique := is_end_based_unique;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                  to_char(l_regular_interval)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_daily_executions THEN
                                                                  to_char(l_daily_executions)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_time_schedule THEN
                                                                  to_char(l_exec_time_option)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time THEN
                                                                  l_tbl_exec_time_parsed(1)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_02 THEN
                                                                  l_tbl_exec_time_parsed(2)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_03 THEN
                                                                  l_tbl_exec_time_parsed(3)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_04 THEN
                                                                  l_tbl_exec_time_parsed(4)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_05 THEN
                                                                  l_tbl_exec_time_parsed(5)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_06 THEN
                                                                  l_tbl_exec_time_parsed(6)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_07 THEN
                                                                  l_tbl_exec_time_parsed(7)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_08 THEN
                                                                  l_tbl_exec_time_parsed(8)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_09 THEN
                                                                  l_tbl_exec_time_parsed(9)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                  decode(l_flg_recurr_pattern, NULL, 'D', '0', 'D', l_flg_recurr_pattern)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                  to_char(coalesce(l_repeat_every, 1))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date
                                                                      AND i_tbl_data(i_idx) (1) NOT IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                  l_start
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                  l_flg_end_by
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after THEN
                                                                  CASE
                                                                      WHEN i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                       NULL
                                                                      ELSE
                                                                       l_end
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                  to_char(l_duration)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_occurrences THEN
                                                                  to_char(l_occurrences)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_root_name THEN
                                                                  i_tbl_data(i_idx) (1)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => t.min_value,
                                       max_value          => t.max_value,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                  to_char(l_regular_interval) ||
                                                                  decode(l_regular_interval,
                                                                         NULL,
                                                                         NULL,
                                                                         ' ' ||
                                                                         pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                      i_prof         => i_prof,
                                                                                                                      i_unit_measure => l_regulat_interval_um))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_daily_executions THEN
                                                                  to_char(l_daily_executions)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_time_schedule THEN
                                                                  l_predef_time_sched_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                  coalesce(l_recurr_pattern_desc,
                                                                           pk_sysdomain.get_domain(i_lang          => i_lang,
                                                                                                   i_prof          => i_prof,
                                                                                                   i_code_dom      => 'ORDER_RECURR_PLAN.FLG_RECURR_PATTERN',
                                                                                                   i_val           => 'D',
                                                                                                   i_dep_clin_serv => NULL))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                  to_char(coalesce(l_repeat_every, 1)) || ' ' ||
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => coalesce(l_unit_meas_repeat_every,
                                                                                                                                          1039))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                  l_end_by_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                  to_char(l_duration) ||
                                                                  decode(l_unit_meas_duration,
                                                                         NULL,
                                                                         NULL,
                                                                         ' ' ||
                                                                         pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                      i_prof         => i_prof,
                                                                                                                      i_unit_measure => l_unit_meas_duration))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_occurrences THEN
                                                                  to_char(l_occurrences) ||
                                                                  decode(l_occurrences, NULL, NULL, ' ' || pk_message.get_message(i_lang, 'ORDER_RECURRENCE_M001'))
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                  coalesce(l_unit_meas_repeat_every, 1039)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                  l_unit_meas_duration
                                                                 ELSE
                                                                  t.id_unit_measure
                                                             END,
                                       desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                          i_prof         => i_prof,
                                                                                                          i_unit_measure => CASE
                                                                                                                                WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                                                                                 l_unit_meas_repeat_every
                                                                                                                                WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                                                                                 l_unit_meas_duration
                                                                                                                                ELSE
                                                                                                                                 t.id_unit_measure
                                                                                                                            END),
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => coalesce(def.flg_event_type,
                                                                      CASE
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after THEN
                                                                           CASE
                                                                               WHEN l_flg_end_by = 'D'
                                                                                    AND l_end_based_unique = pk_alert_constant.g_yes THEN
                                                                                CASE
                                                                                    WHEN i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                                     pk_orders_constant.g_component_inactive
                                                                                    ELSE
                                                                                     pk_orders_constant.g_component_mandatory
                                                                                END
                                                                               WHEN (l_flg_end_by = 'W' AND l_end_based_unique = pk_alert_constant.g_yes)
                                                                                    OR l_end_based_unique = pk_alert_constant.g_no THEN
                                                                                pk_orders_constant.g_component_inactive
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                           CASE
                                                                               WHEN l_flg_end_by IN ('L')
                                                                                    AND l_end_based_unique = pk_alert_constant.g_yes THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_occurrences THEN
                                                                           CASE
                                                                               WHEN l_flg_end_by IN ('N')
                                                                                    AND l_end_based_unique = pk_alert_constant.g_yes THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_time_schedule THEN
                                                                           l_predef_time_sched_status
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                           pk_orders_constant.g_component_active
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_02 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 2
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_03 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 3
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_04 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 4
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_05 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 5
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_06 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 6
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_07 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 7
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_08 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 8
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_09 THEN
                                                                           CASE
                                                                               WHEN l_daily_executions >= 9
                                                                                    AND l_daily_executions IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date
                                                                               AND i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                           pk_orders_constant.g_component_inactive
                                                                          WHEN t.internal_name_child NOT IN (pk_orders_constant.g_ds_start_date) THEN
                                                                           pk_orders_constant.g_component_active
                                                                      END),
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO l_tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure,
                           dc.min_value,
                           dc.max_value
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.internal_name IN (pk_orders_constant.g_ds_regular_intervals,
                                       pk_orders_constant.g_ds_daily_executions,
                                       pk_orders_constant.g_ds_time_schedule,
                                       pk_orders_constant.g_ds_exact_time,
                                       pk_orders_constant.g_ds_exact_time_02,
                                       pk_orders_constant.g_ds_exact_time_03,
                                       pk_orders_constant.g_ds_exact_time_04,
                                       pk_orders_constant.g_ds_exact_time_05,
                                       pk_orders_constant.g_ds_exact_time_06,
                                       pk_orders_constant.g_ds_exact_time_07,
                                       pk_orders_constant.g_ds_exact_time_08,
                                       pk_orders_constant.g_ds_exact_time_09,
                                       pk_orders_constant.g_ds_recurrence_pattern,
                                       pk_orders_constant.g_ds_repeat_every,
                                       pk_orders_constant.g_ds_start_date,
                                       pk_orders_constant.g_ds_end_based,
                                       pk_orders_constant.g_ds_end_after,
                                       pk_orders_constant.g_ds_end_after_n,
                                       pk_orders_constant.g_ds_end_after_occurrences,
                                       pk_orders_constant.g_ds_root_name)
             ORDER BY t.rn;
        
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            IF i_curr_component IS NOT NULL
            THEN
                l_tbl_daily_executions := table_number();
                l_tbl_edit_field_name  := table_varchar();
                l_tbl_edit_field_name.extend();
            
                l_tbl_edit_field_name := table_varchar();
                l_tbl_edit_field_name.extend();
            
                IF i_curr_component IS NOT NULL
                THEN
                    SELECT d.internal_name_child
                      INTO l_curr_comp_int_name
                      FROM ds_cmpt_mkt_rel d
                     WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
                END IF;
            
                IF l_curr_comp_int_name IN (pk_orders_constant.g_ds_regular_intervals)
                THEN
                    l_tbl_edit_field_name(1) := 'REGULAR_INTERVALS';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_daily_executions
                THEN
                    l_tbl_edit_field_name(1) := 'DAILY_EXECUTIONS';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_time_schedule
                THEN
                    l_tbl_edit_field_name(1) := 'PREDEFINED_SCHEDULE';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_02
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_1';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_03
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_2';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_04
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_3';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_05
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_4';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_06
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_5';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_07
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_6';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_08
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_7';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exact_time_09
                THEN
                    l_tbl_edit_field_name(1) := 'EXEC_TIME_8';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_recurrence_pattern
                THEN
                    l_tbl_edit_field_name(1) := 'RECURRENCE_PATTERN';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_repeat_every
                THEN
                    l_tbl_edit_field_name(1) := 'REPEAT_EVERY';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_start_date
                THEN
                    l_tbl_edit_field_name(1) := 'START_DATE';
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_end_based
                THEN
                    l_tbl_edit_field_name(1) := 'END_BY';
                ELSE
                    l_tbl_edit_field_name(1) := 'END_AFTER';
                END IF;
            
                l_tbl_exec_times.extend(9);
            
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    IF i_tbl_int_name(i) = pk_orders_constant.g_ds_regular_intervals
                    THEN
                        l_regular_interval    := to_number(i_value(i) (1));
                        l_regulat_interval_um := to_number(i_value_mea(i) (1));
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_daily_executions
                    THEN
                        l_daily_executions := to_number(i_value(i) (1));
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_time_schedule
                    THEN
                        l_predef_time_sched := to_number(i_value(i) (1));
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_recurrence_pattern
                    THEN
                        l_flg_recurr_pattern := i_value(i) (1);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_repeat_every
                    THEN
                        l_repeat_every := to_number(i_value(i) (1));
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                    THEN
                        l_start := i_value(i) (1);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_end_based
                    THEN
                        l_flg_end_by := i_value(i) (1);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time
                    THEN
                        l_tbl_exec_times(1) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_02
                    THEN
                        l_tbl_exec_times(2) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_03
                    THEN
                        l_tbl_exec_times(3) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_04
                    THEN
                        l_tbl_exec_times(4) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_05
                    THEN
                        l_tbl_exec_times(5) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_06
                    THEN
                        l_tbl_exec_times(6) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_07
                    THEN
                        l_tbl_exec_times(7) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_08
                    THEN
                        l_tbl_exec_times(8) := substr(i_value(i) (1), 9, 4);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_exact_time_09
                    THEN
                        l_tbl_exec_times(9) := substr(i_value(i) (1), 9, 4);
                    END IF;
                END LOOP;
            
                IF l_daily_executions IS NOT NULL
                   AND l_daily_executions > 0
                THEN
                    FOR i IN 1 .. l_daily_executions
                    LOOP
                        l_tbl_number_aux.extend();
                        l_tbl_number_aux(l_tbl_number_aux.count) := NULL;
                    
                        l_tbl_varchar_aux.extend();
                    
                        l_tbl_varchar_aux(l_tbl_varchar_aux.count) := l_tbl_exec_times(i);
                    END LOOP;
                END IF;
            
                IF l_curr_comp_int_name != pk_orders_constant.g_ds_end_based
                THEN
                    IF l_flg_end_by = 'N' --Number of executions
                    THEN
                        l_occurrences := to_number(pk_orders_utils.get_value(pk_orders_constant.g_ds_end_after_occurrences,
                                                                             i_tbl_mkt_rel,
                                                                             i_value));
                    ELSIF l_flg_end_by = 'L' --Duration
                    THEN
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            IF i_tbl_int_name(i) = pk_orders_constant.g_ds_end_after_n
                            THEN
                                l_duration           := to_number(i_value(i) (1));
                                l_unit_meas_duration := to_number(i_value_mea(i) (1));
                                EXIT;
                            END IF;
                        END LOOP;
                    ELSIF l_flg_end_by = 'D' --Date
                    THEN
                        l_end := pk_orders_utils.get_value(pk_orders_constant.g_ds_end_after, i_tbl_mkt_rel, i_value);
                    END IF;
                ELSE
                    --When selecting the 'End based on', the duration fields must be erased
                    l_occurrences := NULL;
                    l_duration    := NULL;
                    l_end         := NULL;
                END IF;
            
                IF NOT pk_order_recurrence_api_ux.check_order_recurr_option(i_lang                       => i_lang,
                                                                            i_prof                       => i_prof,
                                                                            i_order_recurr_plan          => table_number(i_tbl_id_pk(i_idx)),
                                                                            i_edit_field_name            => l_tbl_edit_field_name,
                                                                            i_regular_interval           => table_number(l_regular_interval),
                                                                            i_unit_meas_regular_interval => table_number(l_regulat_interval_um),
                                                                            i_daily_executions           => table_number(l_daily_executions),
                                                                            i_predef_time_sched          => table_table_number(table_number(l_predef_time_sched)),
                                                                            i_exec_time_parent_option    => table_table_number(l_tbl_number_aux),
                                                                            i_exec_time_option           => table_table_number(l_tbl_number_aux),
                                                                            i_exec_time                  => table_table_varchar(l_tbl_varchar_aux),
                                                                            i_flg_recurr_pattern         => table_varchar(l_flg_recurr_pattern),
                                                                            i_repeat_every               => table_number(l_repeat_every),
                                                                            i_flg_repeat_by              => table_varchar(NULL),
                                                                            i_start_date                 => table_varchar(l_start),
                                                                            i_flg_end_by                 => table_varchar(l_flg_end_by),
                                                                            i_occurrences                => table_number(l_occurrences),
                                                                            i_duration                   => table_number(l_duration),
                                                                            i_unit_meas_duration         => table_number(l_unit_meas_duration),
                                                                            i_end_date                   => table_varchar(l_end),
                                                                            i_flg_week_day               => table_table_number(NULL),
                                                                            i_flg_week                   => table_table_number(NULL),
                                                                            i_month_day                  => table_table_number(NULL),
                                                                            i_month                      => table_table_number(NULL),
                                                                            i_flg_context                => 'P',
                                                                            o_order_recurr_plan          => l_tbl_order_recurr_plan,
                                                                            o_regular_interval           => l_tbl_regular_interval,
                                                                            o_unit_meas_regular_interval => l_tbl_unit_meas_reg_interval,
                                                                            o_regular_interval_desc      => l_regular_interval_desc,
                                                                            o_daily_executions           => l_tbl_daily_executions,
                                                                            o_predef_time_sched          => l_tbl_tbl_predef_time_sched,
                                                                            o_predef_time_sched_desc     => l_predef_time_sched_desc,
                                                                            o_exec_times                 => l_exec_times,
                                                                            o_flg_recurr_pattern         => l_tbl_flg_recurr_pattern,
                                                                            o_recurr_pattern_desc        => l_recurr_pattern_desc,
                                                                            o_repeat_every               => l_tbl_repeat_every,
                                                                            o_unit_meas_repeat_every     => l_tbl_unit_meas_repeat_every,
                                                                            o_repeat_every_desc          => l_repeat_every_desc,
                                                                            o_flg_repeat_by              => l_tbl_flg_repeat_by,
                                                                            o_repeat_by_desc             => l_repeat_by_desc,
                                                                            o_start_date                 => l_tbl_start_date,
                                                                            o_start_date_desc            => l_start_date_desc,
                                                                            o_flg_end_by                 => l_tbl_flg_end_by,
                                                                            o_end_by_desc                => l_end_by_desc,
                                                                            o_occurrences                => l_tbl_occurrences,
                                                                            o_duration                   => l_tbl_duration,
                                                                            o_unit_meas_duration         => l_tbl_unit_meas_duration,
                                                                            o_end_date                   => l_tbl_end_date,
                                                                            o_end_after_desc             => l_end_after_desc,
                                                                            o_flg_week_day               => l_tbl_tbl_flg_week_day,
                                                                            o_week_day_desc              => l_week_day_desc,
                                                                            o_flg_week                   => l_tbl_tbl_flg_week,
                                                                            o_week_desc                  => l_week_desc,
                                                                            o_month_day                  => l_tbl_tbl_month_day,
                                                                            o_month                      => l_tbl_tbl_month,
                                                                            o_month_desc                 => l_month_desc,
                                                                            o_flg_regular_interval_edit  => l_flg_regular_interval_edit,
                                                                            o_flg_daily_executions_edit  => l_flg_daily_executions_edit,
                                                                            o_flg_predef_time_sched_edit => l_flg_predef_time_sched_edit,
                                                                            o_flg_exec_time_edit         => l_flg_exec_time_edit,
                                                                            o_flg_repeat_every_edit      => l_flg_repeat_every_edit,
                                                                            o_flg_repeat_by_edit         => l_flg_repeat_by_edit,
                                                                            o_flg_start_date_edit        => l_flg_start_date_edit,
                                                                            o_flg_end_by_edit            => l_flg_end_by_edit,
                                                                            o_flg_end_after_edit         => l_flg_end_after_edit,
                                                                            o_flg_week_day_edit          => l_flg_week_day_edit,
                                                                            o_flg_week_edit              => l_flg_week_edit,
                                                                            o_flg_month_day_edit         => l_flg_month_day_edit,
                                                                            o_flg_month_edit             => l_flg_month_edit,
                                                                            o_flg_ok_avail               => l_flg_ok_avail,
                                                                            o_error                      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                IF l_tbl_start_date(1) IS NOT NULL
                   AND l_tbl_end_date(1) IS NOT NULL
                THEN
                    -- @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise 
                    l_flg_end_date := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                      i_date1 => pk_date_utils.get_string_tstz(i_lang,
                                                                                                               i_prof,
                                                                                                               l_tbl_start_date(1),
                                                                                                               NULL),
                                                                      i_date2 => pk_date_utils.get_string_tstz(i_lang,
                                                                                                               i_prof,
                                                                                                               l_tbl_end_date(1),
                                                                                                               NULL));
                END IF;
            
                IF l_curr_comp_int_name <> pk_orders_constant.g_ds_end_after
                   OR l_flg_end_date <> 'G'
                THEN
                    DECLARE
                        l_id_order_recurr_plan    NUMBER(24);
                        l_exec_time_parent_option NUMBER(24);
                        l_exec_time_option        NUMBER(24);
                        l_exec_time_aux           VARCHAR2(1000 CHAR);
                        l_exec_time_desc_aux      VARCHAR2(1000 CHAR);
                    BEGIN
                        LOOP
                            FETCH l_exec_times
                                INTO l_id_order_recurr_plan,
                                     l_exec_time_parent_option,
                                     l_exec_time_option,
                                     l_exec_time_aux,
                                     l_exec_time_desc_aux;
                            EXIT WHEN l_exec_times%NOTFOUND;
                        
                            l_tbl_exec_times_desc.extend();
                            l_tbl_exec_times_desc(l_tbl_exec_times_desc.count) := l_exec_time_desc_aux;
                        
                            l_tbl_exec_times_aux.extend();
                            l_tbl_exec_times_aux(l_tbl_exec_times_aux.count) := l_exec_time_aux;
                        END LOOP;
                    
                        FOR i IN 1 .. 9
                        LOOP
                            IF l_tbl_exec_times_aux.exists(i)
                               AND l_tbl_exec_times_aux(i) IS NOT NULL
                            THEN
                                l_tbl_exec_time_parsed.extend();
                                l_tbl_exec_time_parsed(l_tbl_exec_time_parsed.count) := '00000101' ||
                                                                                        to_char(l_tbl_exec_times_aux(i)) || '00';
                            ELSIF l_tbl_exec_times.exists(i)
                                  AND l_tbl_exec_times(i) IS NOT NULL
                            THEN
                                l_tbl_exec_time_parsed.extend();
                                l_tbl_exec_time_parsed(l_tbl_exec_time_parsed.count) := '00000101' ||
                                                                                        to_char(l_tbl_exec_times(i)) || '00';
                            ELSE
                                l_tbl_exec_time_parsed.extend();
                                l_tbl_exec_time_parsed(l_tbl_exec_time_parsed.count) := NULL;
                            END IF;
                        END LOOP;
                    END;
                
                    IF l_tbl_regular_interval.exists(1)
                    THEN
                        l_regular_interval := l_tbl_regular_interval(1);
                    ELSE
                        l_regular_interval := NULL;
                    END IF;
                
                    IF l_tbl_unit_meas_reg_interval.exists(1)
                    THEN
                        l_regulat_interval_um := l_tbl_unit_meas_reg_interval(1);
                    ELSE
                        l_regulat_interval_um := NULL;
                    END IF;
                
                    IF l_tbl_daily_executions.exists(1)
                    THEN
                        l_daily_executions := l_tbl_daily_executions(1);
                    ELSE
                        l_daily_executions := NULL;
                    END IF;
                
                    IF l_tbl_exec_times_desc.exists(1)
                    THEN
                        l_exec_time_desc := l_tbl_exec_times_desc(1);
                    ELSE
                        l_exec_time_desc := NULL;
                    END IF;
                
                    IF l_tbl_flg_end_by.exists(1)
                    THEN
                        l_flg_end_by := l_tbl_flg_end_by(1);
                    END IF;
                
                    IF l_tbl_flg_recurr_pattern.exists(1)
                    THEN
                        l_flg_recurr_pattern := l_tbl_flg_recurr_pattern(1);
                    END IF;
                
                    IF l_tbl_repeat_every.exists(1)
                    THEN
                        l_repeat_every := l_tbl_repeat_every(1);
                    END IF;
                
                    IF l_tbl_unit_meas_repeat_every.exists(1)
                    THEN
                        l_unit_meas_repeat_every := l_tbl_unit_meas_repeat_every(1);
                    END IF;
                
                    IF l_tbl_start_date.exists(1)
                    THEN
                        l_start_date_str := l_tbl_start_date(1);
                    END IF;
                
                    IF l_tbl_end_date.exists(1)
                    THEN
                        l_end_date_str := l_tbl_end_date(1);
                    END IF;
                
                    IF l_tbl_unit_meas_duration.exists(1)
                    THEN
                        l_end_after_um := l_tbl_unit_meas_duration(1);
                    END IF;
                
                    IF l_tbl_occurrences.exists(1)
                    THEN
                        l_occurrences := l_tbl_occurrences(1);
                    END IF;
                
                    IF l_tbl_duration.exists(1)
                    THEN
                        l_duration := l_tbl_duration(1);
                    END IF;
                
                    SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                               id_ds_component    => t.id_ds_component_child,
                                               internal_name      => t.internal_name_child,
                                               VALUE              => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                          to_char(l_regular_interval)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_daily_executions THEN
                                                                          to_char(l_daily_executions)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_time_schedule THEN
                                                                          CASE
                                                                              WHEN l_predef_time_sched_desc IS NULL THEN
                                                                               NULL
                                                                              ELSE
                                                                               to_char(l_predef_time_sched)
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time THEN
                                                                          l_tbl_exec_time_parsed(1)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_02 THEN
                                                                          l_tbl_exec_time_parsed(2)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_03 THEN
                                                                          l_tbl_exec_time_parsed(3)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_04 THEN
                                                                          l_tbl_exec_time_parsed(4)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_05 THEN
                                                                          l_tbl_exec_time_parsed(5)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_06 THEN
                                                                          l_tbl_exec_time_parsed(6)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_07 THEN
                                                                          l_tbl_exec_time_parsed(7)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_08 THEN
                                                                          l_tbl_exec_time_parsed(8)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_09 THEN
                                                                          l_tbl_exec_time_parsed(9)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                          l_flg_recurr_pattern
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                          to_char(l_repeat_every)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                          CASE
                                                                              WHEN i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                               NULL
                                                                              ELSE
                                                                               l_start_date_str
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                          l_flg_end_by
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after THEN
                                                                          CASE
                                                                              WHEN i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                               NULL
                                                                              ELSE
                                                                               l_tbl_end_date(1)
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                          to_char(l_duration)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_occurrences THEN
                                                                          to_char(l_occurrences)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_root_name THEN
                                                                          i_tbl_data(i_idx) (1)
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               value_clob         => NULL,
                                               min_value          => t.min_value,
                                               max_value          => t.max_value,
                                               desc_value         => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                          l_regular_interval_desc
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_daily_executions THEN
                                                                          to_char(l_daily_executions)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_time_schedule THEN
                                                                          l_predef_time_sched_desc
                                                                         WHEN t.internal_name_child IN (pk_orders_constant.g_ds_exact_time)
                                                                              AND l_exec_time IS NOT NULL THEN
                                                                          l_exec_time_desc
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                          CASE
                                                                              WHEN i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                               NULL
                                                                              ELSE
                                                                               l_start_date_desc
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_based THEN
                                                                          l_end_by_desc
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_recurrence_pattern THEN
                                                                          l_recurr_pattern_desc
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                          l_repeat_every_desc
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                          to_char(l_duration) ||
                                                                          decode(l_duration,
                                                                                 NULL,
                                                                                 NULL,
                                                                                 ' ' ||
                                                                                 pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                              i_prof         => i_prof,
                                                                                                                              i_unit_measure => l_end_after_um))
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_occurrences THEN
                                                                          to_char(l_occurrences) ||
                                                                          decode(l_occurrences,
                                                                                 NULL,
                                                                                 NULL,
                                                                                 ' ' || pk_message.get_message(i_lang, 'ORDER_RECURRENCE_M001'))
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               desc_clob          => NULL,
                                               id_unit_measure    => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                          l_regulat_interval_um
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                          l_unit_meas_repeat_every
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                          l_end_after_um
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               desc_unit_measure  => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_regular_intervals THEN
                                                                          pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                       i_prof         => i_prof,
                                                                                                                       i_unit_measure => l_regulat_interval_um)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                          pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                       i_prof         => i_prof,
                                                                                                                       i_unit_measure => l_unit_meas_repeat_every)
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                          pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                       i_prof         => i_prof,
                                                                                                                       i_unit_measure => l_end_after_um)
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               flg_validation     => pk_orders_constant.g_component_valid,
                                               err_msg            => NULL,
                                               flg_event_type     => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after THEN
                                                                          CASE
                                                                              WHEN l_flg_end_by = 'D' THEN
                                                                               CASE
                                                                                   WHEN i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                                    pk_orders_constant.g_component_inactive
                                                                                   ELSE
                                                                                    pk_orders_constant.g_component_mandatory
                                                                               END
                                                                              WHEN l_flg_end_by = 'W' THEN
                                                                               pk_orders_constant.g_component_inactive
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_n THEN
                                                                          CASE
                                                                              WHEN l_flg_end_by IN ('L') THEN
                                                                               pk_orders_constant.g_component_mandatory
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_end_after_occurrences THEN
                                                                          CASE
                                                                              WHEN l_flg_end_by IN ('N') THEN
                                                                               pk_orders_constant.g_component_mandatory
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time
                                                                              AND l_regular_interval IS NOT NULL THEN
                                                                          pk_orders_constant.g_component_inactive
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time
                                                                              AND l_regular_interval IS NULL THEN
                                                                          pk_orders_constant.g_component_active
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_repeat_every THEN
                                                                          CASE
                                                                              WHEN l_flg_recurr_pattern = '0' THEN
                                                                               pk_orders_constant.g_component_inactive
                                                                              ELSE
                                                                               pk_orders_constant.g_component_active
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_02 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 2
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_03 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 3
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_04 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 4
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_05 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 5
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_06 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 6
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_07 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 7
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_08 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 8
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_exact_time_09 THEN
                                                                          CASE
                                                                              WHEN l_daily_executions >= 9
                                                                                   AND l_daily_executions IS NOT NULL THEN
                                                                               nvl2(l_tbl_exec_time_parsed(1),
                                                                                    pk_orders_constant.g_component_mandatory,
                                                                                    pk_orders_constant.g_component_read_only)
                                                                              ELSE
                                                                               pk_orders_constant.g_component_hidden
                                                                          END
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                          CASE
                                                                              WHEN i_tbl_data(i_idx) (1) IN (pk_orders_constant.g_ds_order_set_procedure) THEN
                                                                               pk_orders_constant.g_component_inactive
                                                                              ELSE
                                                                               pk_orders_constant.g_component_active
                                                                          END
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               flg_multi_status   => NULL,
                                               idx                => i_idx)
                      BULK COLLECT
                      INTO l_tbl_result
                      FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                   dc.id_ds_component_child,
                                   dc.internal_name_child,
                                   dc.flg_event_type,
                                   dc.rn,
                                   dc.flg_component_type_child,
                                   dc.min_value,
                                   dc.max_value
                              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_patient        => NULL,
                                                                 i_component_name => i_root_name,
                                                                 i_action         => NULL)) dc) t
                      JOIN ds_component d
                        ON d.id_ds_component = t.id_ds_component_child
                     WHERE d.flg_component_type = 'L';
                END IF;
            
                IF l_flg_end_date = 'G'
                THEN
                    SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                              id_ds_component    => t.id_ds_component_child,
                                              internal_name      => t.internal_name_child,
                                              VALUE              => l_end,
                                              value_clob         => NULL,
                                              min_value          => t.min_value,
                                              max_value          => t.max_value,
                                              desc_value         => NULL,
                                              desc_clob          => NULL,
                                              id_unit_measure    => NULL,
                                              desc_unit_measure  => NULL,
                                              flg_validation     => pk_orders_constant.g_component_error,
                                              err_msg            => pk_message.get_message(i_lang, 'MONITOR_M010'),
                                              flg_event_type     => pk_orders_constant.g_component_mandatory,
                                              flg_multi_status   => NULL,
                                              idx                => i_idx)
                      BULK COLLECT
                      INTO l_tbl_result
                      FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                   dc.id_ds_component_child,
                                   dc.internal_name_child,
                                   dc.flg_event_type,
                                   dc.rn,
                                   dc.flg_component_type_child,
                                   dc.min_value,
                                   dc.max_value
                              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_patient        => NULL,
                                                                 i_component_name => i_root_name,
                                                                 i_action         => NULL)) dc) t
                      JOIN ds_component d
                        ON d.id_ds_component = t.id_ds_component_child
                     WHERE d.flg_component_type = 'L'
                       AND d.internal_name = pk_orders_constant.g_ds_end_after;
                END IF;
            END IF;
        END IF;
    
        RETURN l_tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN t_tbl_ds_get_value();
    END get_other_frequencies_values;

    FUNCTION get_generic_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_GENERIC_FORM_VALUES';
    
        --Return variable
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        --Control variables to cycle through the input parameters
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        --Variable to indicate if we are dealing with a new request or an edition
        l_flg_edition VARCHAR2(1) := pk_alert_constant.g_no;
    
        --Variables for the Clinical indication block
        l_clinical_indication_mandatory sys_config.value%TYPE := pk_alert_constant.g_no;
        l_clinical_purpose_mandatory    sys_config.value%TYPE := pk_alert_constant.g_no;
        l_laterality_mandatory          sys_config.value%TYPE := pk_alert_constant.g_no;
        l_flg_laterality                VARCHAR2(1 CHAR);
        l_flg_laterality_default        VARCHAR2(1 CHAR);
        l_laterality_desc               VARCHAR2(200 CHAR);
    
        --Variables for the Instructions block
        l_flg_prn                 VARCHAR2(1) := pk_alert_constant.g_no;
        l_flg_time                VARCHAR2(1 CHAR);
        l_time_desc               VARCHAR2(1000 CHAR);
        l_tbl_flg_time            table_varchar := table_varchar();
        l_tbl_next_episode        table_varchar := table_varchar();
        l_tbl_no_later_than       table_varchar := table_varchar();
        l_id_epis_to_execute      episode.id_episode%TYPE;
        l_epis_to_execute_desc    VARCHAR2(1000 CHAR);
        l_order_frequency_default sys_config.value%TYPE;
        l_dt_epis_begin           episode.dt_begin_tstz%TYPE;
        l_epis_begin_verification VARCHAR2(1 CHAR);
    
        --Recurrence variables
        l_order_recurr_desc          VARCHAR2(4000);
        l_order_recurr_option        order_recurr_plan.id_order_recurr_option%TYPE;
        l_start_date                 order_recurr_plan.start_date%TYPE;
        l_occurrences                order_recurr_plan.occurrences%TYPE;
        l_duration                   order_recurr_plan.duration%TYPE;
        l_duration_desc              VARCHAR2(4000);
        l_unit_meas_duration         order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date                   order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable        VARCHAR2(1);
        l_order_recurr_plan          order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_plan_original order_recurr_plan.id_order_recurr_plan%TYPE;
    
        l_tbl_order_recurr_plan   table_number := table_number();
        l_tbl_order_recurr_option table_number := table_number();
        l_tbl_order_recurr_desc   table_varchar := table_varchar();
        l_tbl_start_date          table_varchar := table_varchar();
        l_start_date_str          VARCHAR2(500);
        l_tbl_flg_end_by_editable table_varchar := table_varchar();
        l_end_date_str            VARCHAR2(500);
        l_tbl_occurrences         table_number := table_number();
        l_tbl_duration            table_number := table_number();
        l_tbl_duration_desc       table_varchar := table_varchar();
        l_tbl_unit_meas_duration  table_number := table_number();
        l_tbl_end_date            table_varchar := table_varchar();
    
        --Variables for the Execution block
        l_id_intervention           VARCHAR2(100 CHAR); --Dummy to fetch the lab test results for the procedures
        l_weight                    VARCHAR2(100 CHAR);
        l_analysis_result           VARCHAR2(4000 CHAR);
        l_dummy_cursor              pk_types.cursor_type;
        l_notes_tech_mandatory      sys_config.value%TYPE;
        l_notes_execution_mandatory sys_config.value%TYPE;
        --Supplies
        l_tbl_supply      table_varchar := table_varchar();
        l_tbl_supply_desc table_varchar := table_varchar();
        l_supply_desc     VARCHAR2(4000 CHAR) := NULL;
        l_tbl_set         table_varchar := table_varchar();
        l_tbl_quantity    table_varchar := table_varchar();
        l_tbl_dt_return   table_varchar := table_varchar();
        l_tbl_supply_loc  table_varchar := table_varchar();
    
        --Variables for the CO_SIGN block
        l_co_sign_available   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_external_ordered_by sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_code_cf => 'EXTERNAL_ORDERED_BY_MANDATORY',
                                                                                   i_prof    => i_prof),
                                                           pk_alert_constant.g_yes);
        l_default_prof        t_tbl_core_domain;
        l_id_order_type       order_type.id_order_type%TYPE;
        l_id_default_prof     professional.id_professional%TYPE;
        l_default_prof_name   professional.name%TYPE;
        l_has_cosign_info     VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        --Variables for the Not_Ordering block
        l_flg_show_reason_not_order sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'SHOW_REASON_NOT_ORDERING',
                                                                                     i_prof    => i_prof);
    
        --Variables for the Healthcare insurance block    
        l_show_healthcare_insurance sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_code_cf => 'MCDT_HEALTH_INSURANCE',
                                                                                             i_prof    => i_prof);
        l_has_catalogue             VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                             i_id_institution => i_prof.institution);
    
        l_tbl_catalogue          t_tbl_core_domain := t_tbl_core_domain();
        l_id_catalogue_default   codification.id_codification%TYPE;
        l_desc_catalogue_default translation.desc_lang_1%TYPE;
    
        l_id_financial_entity     NUMBER(24);
        l_id_health_coverage_plan NUMBER(24);
        l_beneficiary_number      VARCHAR2(1000 CHAR);
        l_exemption_desc          VARCHAR2(1000 CHAR);
        l_id_pat_exemption        NUMBER(24);
        l_id_exemption            NUMBER(24);
        l_id_pat_health_plan      NUMBER(24);
    
        --PATIENT INFORMATION
        l_pat_name              patient.name%TYPE;
        l_gender                patient.gender%TYPE;
        l_desc_gender           VARCHAR2(100);
        l_dt_birth              VARCHAR2(100);
        l_dt_deceased           VARCHAR2(100);
        l_flg_migrator          pat_soc_attributes.flg_migrator%TYPE;
        l_id_country_nation     country.alpha2_code%TYPE;
        l_sns                   pat_health_plan.num_health_plan%TYPE;
        l_valid_sns             VARCHAR2(100);
        l_flg_occ_disease       VARCHAR2(100);
        l_flg_independent       VARCHAR2(100);
        l_hp_entity             VARCHAR2(100);
        l_flg_recm              VARCHAR2(100);
        l_main_phone            VARCHAR2(100);
        l_hp_alpha2_code        VARCHAR2(100);
        l_hp_country_desc       VARCHAR2(100);
        l_hp_national_ident_nbr VARCHAR2(100);
        l_hp_dt_effective       VARCHAR2(100);
        l_valid_hp              VARCHAR2(100);
        l_flg_type_hp           health_plan.flg_type%TYPE;
        l_hp_id_content         health_plan.id_content%TYPE;
        l_hp_inst_ident_nbr     pat_health_plan.inst_identifier_number%TYPE;
        l_hp_inst_ident_desc    pat_health_plan.inst_identifier_desc%TYPE;
        l_hp_dt_valid           VARCHAR2(100);
    
        --CPOE variables
        l_ts_cpoe_start      cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end        cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_presc cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_proc_exists        BOOLEAN;
    
        --Auxiliar variables
        l_tbl_varchar_aux table_varchar := table_varchar();
        l_varchar_aux     VARCHAR2(4000 CHAR);
        l_date_comparison VARCHAR2(1 CHAR);
    
        /*###########################################*/
        --PROCEDURES (NEW REQUEST)
        --i_tbl_data(i_idx)(1) => id_intervention
        --i_tbl_data(i_idx)(2) => id_codification
        --i_tbl_data(i_idx)(3) => flg_laterality_mcdt
        --i_tbl_data(i_idx)(4) => cpoe_filter
    
        --IMAGING EXAMS / OTHER EXAMS (NEW REQUEST)
        --i_tbl_data(i_idx)(1) => id_exam
        --i_tbl_data(i_idx)(2) => id_codification
        --i_tbl_data(i_idx)(3) => flg_laterality_mcdt  
        --i_tbl_data(i_idx)(4) => cpoe_filter  
        --i_tbl_data(i_idx)(5) => flg_type     
    
        --LAB TESTS (NEW REQUEST)
        --i_tbl_data(i_idx)(1) => id_analysis
        --i_tbl_data(i_idx)(2) => id_sample_type
        --i_tbl_data(i_idx)(3) => flg_type (A-Analysis/G-Group)  
        --i_tbl_data(i_idx)(4) => cpoe_filter
        --i_tbl_data(i_idx)(5) => id_group
        /*###########################################*/
    
    BEGIN
        --An nvl is performed for the sysdate in order to assure the same current date for every i_idx iteration
        g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        --A context variable must be created for the modal windows, called from the current form, to know the root name of the form that made the call
        --This variable should only be set for a new form or when editing (there is no need to generate it for the other submit actions)
        IF i_idx = 1
           AND (i_action <> pk_dyn_form_constant.get_submit_action OR i_action IS NULL)
        THEN
            pk_context_api.set_parameter(p_name => 'root_origin', p_value => i_root_name);
        END IF;
    
        IF i_action IS NULL
           OR i_action = -1 --NEW FORM (default values)
        THEN
            IF i_root_name = pk_orders_constant.g_ds_procedure_request
            THEN
                --Obtain the information for the Weight and Lab tests result fields (Execution block)
                g_error := 'ERROR CALLING PK_PROCEDURES_API_UX.GET_PROCEDURE_PARAMETER_LIST';
                IF NOT pk_procedures_api_ux.get_procedure_parameter_list(i_lang            => i_lang,
                                                                         i_prof            => i_prof,
                                                                         i_patient         => i_patient,
                                                                         i_intervention    => table_number(to_number(i_tbl_data(i_idx) (1))),
                                                                         o_weight          => l_weight,
                                                                         o_analysis_result => l_dummy_cursor,
                                                                         o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'O_ANALYSIS_RESULT LOOP';
                LOOP
                    FETCH l_dummy_cursor
                        INTO l_id_intervention, l_analysis_result;
                    EXIT WHEN l_dummy_cursor%NOTFOUND;
                END LOOP;
            
                --Verify if the Healthcare insurance block should be displayed
                IF l_show_healthcare_insurance = pk_alert_constant.g_yes
                THEN
                    g_error         := 'ERROR CALLING PK_PROCEDURES_CORE.GET_PROCEDURE_CODIFICATION_LIST';
                    l_tbl_catalogue := pk_procedures_core.get_procedure_codification_list(i_lang         => i_lang,
                                                                                          i_prof         => i_prof,
                                                                                          i_intervention => i_tbl_data(i_idx) (1),
                                                                                          i_flg_default  => pk_alert_constant.g_yes);
                
                    IF l_tbl_catalogue.count > 0
                    THEN
                        l_id_catalogue_default   := to_number(l_tbl_catalogue(1).domain_value);
                        l_desc_catalogue_default := l_tbl_catalogue(1).desc_domain;
                        l_has_catalogue          := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            
                --Get the default laterality
                IF i_tbl_data(i_idx) (3) NOT IN ('O', 'A')
                THEN
                    l_flg_laterality := i_tbl_data(i_idx) (3);
                
                    l_laterality_desc := pk_sysdomain.get_domain(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_code_dom      => 'INTERV_PRESC_DET.FLG_LATERALITY',
                                                                 i_val           => l_flg_laterality,
                                                                 i_dep_clin_serv => NULL);
                END IF;
            
                l_flg_laterality_default := i_tbl_data(i_idx) (3);
            ELSIF i_root_name IN
                  (pk_orders_constant.g_ds_imaging_exam_request, pk_orders_constant.g_ds_other_exam_request)
            THEN
                --Verify if the Healthcare insurance block should be displayed
                IF l_show_healthcare_insurance = pk_alert_constant.g_yes
                THEN
                    g_error         := 'ERROR CALLING PK_EXAM_CORE.GET_EXAM_CODIFICATION_LIST';
                    l_tbl_catalogue := pk_exam_core.get_exam_codification_list(i_lang        => i_lang,
                                                                               i_prof        => i_prof,
                                                                               i_exams       => i_tbl_data(i_idx) (1),
                                                                               i_flg_default => pk_alert_constant.g_yes);
                
                    IF l_tbl_catalogue.count > 0
                    THEN
                        l_id_catalogue_default   := to_number(l_tbl_catalogue(1).domain_value);
                        l_desc_catalogue_default := l_tbl_catalogue(1).desc_domain;
                        l_has_catalogue          := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            
                --Get the default laterality
                IF i_tbl_data(i_idx) (3) NOT IN ('O', 'A')
                THEN
                    l_flg_laterality  := i_tbl_data(i_idx) (3);
                    l_laterality_desc := pk_sysdomain.get_domain(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_code_dom      => 'EXAM_REQ_DET.FLG_LATERALITY',
                                                                 i_val           => l_flg_laterality,
                                                                 i_dep_clin_serv => NULL);
                END IF;
            
                l_flg_laterality_default := i_tbl_data(i_idx) (3);
            END IF;
        
            --Obtain the SYS_CONFIGS
            IF i_root_name = pk_orders_constant.g_ds_lab_test_request
            THEN
                l_clinical_indication_mandatory := pk_sysconfig.get_config('LAB_TESTS_CLINICAL_INDICATION_MANDATORY',
                                                                           i_prof);
                l_clinical_purpose_mandatory    := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_A', i_prof);
                l_order_frequency_default       := pk_sysconfig.get_config('LAB_TESTS_ORDER_FREQUENCY_DEFAULT', i_prof);
                l_notes_execution_mandatory     := pk_sysconfig.get_config('LAB_TESTS_NOTES_TECH_MANDATORY', i_prof);
            ELSIF i_root_name = 'DS_BLOOD_PRODUCTS'
            THEN
                l_clinical_purpose_mandatory := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_BP', i_prof);
            ELSIF i_root_name = pk_orders_constant.g_ds_procedure_request
            THEN
                l_clinical_purpose_mandatory := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_P', i_prof);
                l_laterality_mandatory       := pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY', i_prof);
            ELSIF i_root_name = pk_orders_constant.g_ds_imaging_exam_request
            THEN
                l_clinical_indication_mandatory := pk_sysconfig.get_config('IMG_CLINICAL_INDICATION_MANDATORY', i_prof);
                l_clinical_purpose_mandatory    := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_I', i_prof);
                l_laterality_mandatory          := pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY', i_prof);
                l_order_frequency_default       := pk_sysconfig.get_config('IMG_ORDER_FREQUENCY_DEFAULT', i_prof);
                l_notes_tech_mandatory          := pk_sysconfig.get_config('IMG_NOTES_TECH_MANDATORY', i_prof);
            ELSIF i_root_name = pk_orders_constant.g_ds_other_exam_request
            THEN
                l_clinical_indication_mandatory := pk_sysconfig.get_config('EXM_CLINICAL_INDICATION_MANDATORY', i_prof);
                l_clinical_purpose_mandatory    := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_E', i_prof);
                l_laterality_mandatory          := pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY', i_prof);
                l_order_frequency_default       := pk_sysconfig.get_config('EXM_ORDER_FREQUENCY_DEFAULT', i_prof);
                l_notes_tech_mandatory          := pk_sysconfig.get_config('EXM_NOTES_TECH_MANDATORY', i_prof);
            END IF;
        
            --Obtaining the recurrence and the default values for the following fields:
            --FREQUENCY/START DATE/EXECUTIONS/DURATION/UNIT MEASURE/END DATE
            --This should only be called for the first iteration (i_idx=1)   
            IF i_action IS NULL
               AND i_idx = 1
            THEN
                g_error := 'ERROR CALLING PK_ORDER_RECURRENCE_CORE.CREATE_ORDER_RECURR_PLAN';
                IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                         i_prof                => i_prof,
                                                                         i_order_recurr_area   => CASE i_root_name
                                                                                                      WHEN 'DS_BLOOD_PRODUCTS' THEN
                                                                                                       'BLOOD_PRODUCTS'
                                                                                                      WHEN
                                                                                                       pk_orders_constant.g_ds_health_education_order THEN
                                                                                                       'PATIENT_EDUCATION'
                                                                                                      WHEN
                                                                                                       pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                       'LAB_TEST'
                                                                                                      WHEN
                                                                                                       pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                       'IMAGE_EXAM'
                                                                                                      WHEN
                                                                                                       pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                       'OTHER_EXAM'
                                                                                                      WHEN
                                                                                                       pk_orders_constant.g_ds_procedure_request THEN
                                                                                                       'PROCEDURE'
                                                                                                  END,
                                                                         o_order_recurr_desc   => l_order_recurr_desc,
                                                                         o_order_recurr_option => l_order_recurr_option,
                                                                         o_start_date          => l_start_date,
                                                                         o_occurrences         => l_occurrences,
                                                                         o_duration            => l_duration,
                                                                         o_unit_meas_duration  => l_unit_meas_duration,
                                                                         o_end_date            => l_end_date,
                                                                         o_flg_end_by_editable => l_flg_end_by_editable,
                                                                         o_order_recurr_plan   => l_order_recurr_plan,
                                                                         o_error               => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_order_recurr_plan_original := l_order_recurr_plan;
            
                --The recurrence id is only generated for the 1st record, therefore,
                --it is necessary to store this variable in a context variable,
                --this way, the subsequent records (i_idx > 1) will have access to this variable
                pk_context_api.set_parameter(p_name  => 'l_order_recurr_plan_original',
                                             p_value => l_order_recurr_plan_original);
            
                --Verify if the user needs co_sign to perform the request
                --The verification is only performed for the first record, the remaining records use the context variable
                --If there is no need for co_sign, the block will remain hidden
                g_error := 'ERROR CALLING PK_CO_SIGN_UX.CHECK_PROF_NEEDS_COSIGN_ORDER';
                IF NOT pk_co_sign_ux.check_prof_needs_cosign_order(i_lang                 => i_lang,
                                                                   i_prof                 => i_prof,
                                                                   i_episode              => i_episode,
                                                                   i_task_type            => CASE i_root_name
                                                                                                 WHEN
                                                                                                  pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                  11
                                                                                                 WHEN
                                                                                                  pk_orders_constant.g_ds_procedure_request THEN
                                                                                                  43
                                                                                                 WHEN
                                                                                                  pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                  7
                                                                                                 WHEN
                                                                                                  pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                  8
                                                                                             END,
                                                                   o_flg_prof_need_cosign => l_co_sign_available,
                                                                   o_error                => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                pk_context_api.set_parameter(p_name => 'l_co_sign_available', p_value => l_co_sign_available);
            ELSIF i_idx > 1
            THEN
                --For the subsequent iterations (i_idx > 1) it is necessary to obtain the id_order_recurrence from the first iteration
                l_order_recurr_plan_original := alert_context('l_order_recurr_plan_original');
            
                IF l_order_recurr_plan_original IS NOT NULL
                THEN
                    g_error := 'ERROR CALLING PK_ORDER_RECURRENCE_CORE.COPY_ORDER_RECURR_PLAN';
                    IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                           i_prof                   => i_prof,
                                                                           i_order_recurr_plan_from => l_order_recurr_plan_original,
                                                                           o_order_recurr_desc      => l_order_recurr_desc,
                                                                           o_order_recurr_option    => l_order_recurr_option,
                                                                           o_start_date             => l_start_date,
                                                                           o_occurrences            => l_occurrences,
                                                                           o_duration               => l_duration,
                                                                           o_unit_meas_duration     => l_unit_meas_duration,
                                                                           o_end_date               => l_end_date,
                                                                           o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                           o_order_recurr_plan      => l_order_recurr_plan,
                                                                           o_error                  => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                --Verify if the user needs co_sign to perform the request (value calculated for i_idx = 1)
                l_co_sign_available := alert_context('l_co_sign_available');
            END IF;
        
            --Get the default option for the 'To execute' list 
            --The id_order_recurr_plan will indicate the area to where the form belongs (procedures, lab tests, etc.)
            g_error := 'CALLING  - i_id_order_recurr_plan: ' || l_order_recurr_plan_original;
            BEGIN
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.domain_value, t.desc_domain
                  INTO l_flg_time, l_time_desc
                  FROM TABLE(pk_orders_utils.get_time_list(i_lang                 => i_lang,
                                                           i_prof                 => i_prof,
                                                           i_id_episode           => i_episode,
                                                           i_id_order_recurr_plan => l_order_recurr_plan_original,
                                                           i_flg_default          => pk_alert_constant.g_yes)) t;
            EXCEPTION
                WHEN OTHERS THEN
                    l_flg_time  := NULL;
                    l_time_desc := NULL;
            END;
        
            --Healthcare insurance block verification
            IF l_show_healthcare_insurance = pk_alert_constant.g_yes
            THEN
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    IF i_tbl_int_name(i) = pk_orders_constant.g_ds_exemption
                    THEN
                        g_error := 'ERROR CALLING PK_ORDERS_UTILS.GET_PAT_DEFAULT_EXEMPTION';
                        IF NOT pk_orders_utils.get_pat_default_exemption(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_id_patient     => i_patient,
                                                                         i_current_date   => NULL,
                                                                         o_id_exemption   => l_id_pat_exemption,
                                                                         o_exemption_desc => l_exemption_desc)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        IF l_id_pat_exemption IS NOT NULL
                        THEN
                            SELECT pi.id_isencao
                              INTO l_id_exemption
                              FROM pat_isencao pi
                             WHERE pi.id_pat_isencao = l_id_pat_exemption;
                        END IF;
                    
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_financial_entity
                    THEN
                        --The default value for financial entity should only calculated for the PT market
                        IF l_id_market = pk_alert_constant.g_id_market_pt
                        THEN
                            g_error := 'ERROR CALLING PK_ADT.GET_PAT_INFO';
                            IF NOT pk_adt.get_pat_info(i_lang                    => i_lang,
                                                       i_id_patient              => i_patient,
                                                       i_prof                    => i_prof,
                                                       i_id_episode              => i_episode,
                                                       i_flg_info_for_medication => CASE l_id_market
                                                                                        WHEN pk_alert_constant.g_id_market_pt THEN
                                                                                         pk_alert_constant.g_yes --To fetch the SNS
                                                                                        ELSE
                                                                                         NULL
                                                                                    END,
                                                       o_name                    => l_pat_name,
                                                       o_gender                  => l_gender,
                                                       o_desc_gender             => l_desc_gender,
                                                       o_dt_birth                => l_dt_birth,
                                                       o_dt_deceased             => l_dt_deceased,
                                                       o_flg_migrator            => l_flg_migrator,
                                                       o_id_country_nation       => l_id_country_nation,
                                                       o_sns                     => l_sns,
                                                       o_valid_sns               => l_valid_sns,
                                                       o_flg_occ_disease         => l_flg_occ_disease,
                                                       o_flg_independent         => l_flg_independent,
                                                       o_num_health_plan         => l_beneficiary_number,
                                                       o_hp_entity               => l_hp_entity,
                                                       o_id_health_plan          => l_id_health_coverage_plan,
                                                       o_flg_recm                => l_flg_recm,
                                                       o_main_phone              => l_main_phone,
                                                       o_hp_alpha2_code          => l_hp_alpha2_code,
                                                       o_hp_country_desc         => l_hp_country_desc,
                                                       o_hp_national_ident_nbr   => l_hp_national_ident_nbr,
                                                       o_hp_dt_effective         => l_hp_dt_effective,
                                                       o_valid_hp                => l_valid_hp,
                                                       o_flg_type_hp             => l_flg_type_hp,
                                                       o_hp_id_content           => l_hp_id_content,
                                                       o_hp_inst_ident_nbr       => l_hp_inst_ident_nbr,
                                                       o_hp_inst_ident_desc      => l_hp_inst_ident_desc,
                                                       o_hp_dt_valid             => l_hp_dt_valid,
                                                       o_error                   => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            IF l_beneficiary_number IS NOT NULL
                               AND l_valid_hp = pk_alert_constant.g_yes
                            THEN
                                BEGIN
                                    SELECT hpe.id_health_plan_entity, php.id_pat_health_plan
                                      INTO l_id_financial_entity, l_id_pat_health_plan
                                      FROM pat_health_plan php
                                      JOIN health_plan hp
                                        ON php.id_health_plan = hp.id_health_plan
                                      LEFT JOIN health_plan_entity hpe
                                        ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                     WHERE php.num_health_plan = l_beneficiary_number
                                       AND php.id_patient = i_patient
                                       AND php.id_health_plan = l_id_health_coverage_plan
                                       AND php.id_institution = i_prof.institution
                                       AND php.flg_status = pk_alert_constant.g_active;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        l_beneficiary_number      := NULL;
                                        l_id_pat_health_plan      := NULL;
                                        l_id_health_coverage_plan := NULL;
                                END;
                            ELSIF l_beneficiary_number IS NOT NULL
                                  AND l_valid_hp = pk_alert_constant.g_no
                            THEN
                                l_beneficiary_number := NULL;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            --Data for the tbl_records field
            --It's considered that the first value of each subarray are the ones to be stored.
            --Its purpose it's to be used for the Place and Catalog            
            --Procedures => id_intervention
            --Imaging/Other exams => id_exam            
            --Lab tests => id_analysis
            FOR i IN i_tbl_data.first .. i_tbl_data.last
            LOOP
                l_tbl_varchar_aux.extend;
                l_tbl_varchar_aux(l_tbl_varchar_aux.count) := i_tbl_data(i) (1);
            END LOOP;
        
            --Check if it is necessary to see the prescription limits
            --(only necessary if the request comes from the advanced cpoe)
            IF i_idx = 1
               AND cardinality(i_tbl_data(i_idx)) > 3
               AND i_tbl_data(i_idx) (4) IS NOT NULL
            THEN
                pk_cpoe.get_presc_limits(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_episode,
                                         i_filter         => i_tbl_data(i_idx) (4),
                                         i_task_type      => CASE i_root_name
                                                                 WHEN pk_orders_constant.g_ds_lab_test_request THEN
                                                                  11
                                                                 WHEN pk_orders_constant.g_ds_procedure_request THEN
                                                                  43
                                                                 WHEN pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                  7
                                                                 WHEN pk_orders_constant.g_ds_other_exam_request THEN
                                                                  8
                                                             END,
                                         o_ts_presc_start => l_ts_cpoe_start,
                                         o_ts_presc_end   => l_ts_cpoe_end,
                                         o_ts_next_presc  => l_ts_cpoe_next_presc,
                                         o_proc_exists    => l_proc_exists);
            
                --After obtaining the start date from the prescription limits, it is necessary to compare it to the start date
                --given by the order recurrence api, and check wich date is more recent
                IF l_ts_cpoe_start IS NOT NULL
                   AND pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                       i_date1 => l_ts_cpoe_start,
                                                       i_date2 => l_start_date) = 'G'
                THEN
                    -- @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise 
                    l_start_date := l_ts_cpoe_start;
                
                    IF NOT pk_order_recurrence_api_ux.set_order_recurr_instructions(i_lang                => i_lang,
                                                                                    i_prof                => i_prof,
                                                                                    i_order_recurr_plan   => l_order_recurr_plan_original,
                                                                                    i_start_date          => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                                         i_date => l_start_date,
                                                                                                                                         i_prof => i_prof),
                                                                                    i_occurrences         => l_occurrences,
                                                                                    i_duration            => l_duration,
                                                                                    i_unit_meas_duration  => l_unit_meas_duration,
                                                                                    i_end_date            => l_end_date_str,
                                                                                    o_order_recurr_desc   => l_order_recurr_desc,
                                                                                    o_order_recurr_option => l_order_recurr_option,
                                                                                    o_start_date          => l_start_date_str,
                                                                                    o_occurrences         => l_occurrences,
                                                                                    o_duration            => l_duration,
                                                                                    o_unit_meas_duration  => l_unit_meas_duration,
                                                                                    o_duration_desc       => l_duration_desc,
                                                                                    o_end_date            => l_end_date_str,
                                                                                    o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                    o_order_recurr_plan   => l_order_recurr_plan_original,
                                                                                    o_error               => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END IF;
        
            --Insert the default values in the return variable (tbl_result)
            g_error := 'SELECT INTO TBL_RESULT';
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                  WHEN t.internal_name_child IN (pk_orders_constant.g_ds_laterality) THEN
                                                                  --Default value to be shown on the form. (It should only be displayed if
                                                                  --the value is different than 'O' or 'A')
                                                                   l_flg_laterality
                                                                  WHEN t.internal_name_child IN (pk_orders_constant.g_ds_default_laterality) THEN
                                                                  --Auxiliar variable to list the options from the laterality multichoice (pk_mcdt.get_laterality_all)
                                                                  --When the value is 'O' all options should be listed, when it's 'R' only the 'Right' option
                                                                 --should be listed, etc.
                                                                 --For multiple records, the list is be an intersection of all values.                                                          
                                                                  l_flg_laterality_default
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_to_execute_list THEN
                                                                  l_flg_time
                                                                 WHEN t.internal_name_child IN
                                                                      (pk_orders_constant.g_ds_start_date, pk_orders_constant.g_ds_date_dummy) THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_start_date, i_prof => i_prof)
                                                                 WHEN t.internal_name_child IN (pk_orders_constant.g_ds_execution_ordered_at) THEN
                                                                  decode(l_co_sign_available,
                                                                         pk_alert_constant.g_no,
                                                                         pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_start_date, i_prof => i_prof),
                                                                         NULL)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency THEN
                                                                  decode(l_order_frequency_default, pk_alert_constant.g_no, NULL, to_char(l_order_recurr_option))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                  to_char(l_occurrences)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  CASE
                                                                      WHEN l_duration IS NOT NULL THEN
                                                                       to_char(l_duration)
                                                                      ELSE
                                                                       NULL
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_weight_kg THEN
                                                                  l_weight
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_lab_test_result THEN
                                                                  l_analysis_result
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_catalogue THEN
                                                                  to_char(l_id_catalogue_default)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_financial_entity THEN
                                                                  to_char(l_id_financial_entity)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_coverage_plan THEN
                                                                  to_char(l_id_pat_health_plan)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_plan_number THEN
                                                                  to_char(l_beneficiary_number)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exemption THEN
                                                                  to_char(l_id_exemption)
                                                             --DUMMY FIELDS
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_dummy_number THEN
                                                                  to_char(l_order_recurr_plan)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_flg_edition THEN
                                                                  l_flg_edition
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_root_name THEN
                                                                  i_root_name
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_co_sign_control THEN
                                                                  l_co_sign_available
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_healthcare_insurance_cat_control THEN
                                                                  l_show_healthcare_insurance
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_tbl_records THEN
                                                                  (SELECT listagg(t.column_value, '|') /*+opt_estimate(table t rows=1)*/
                                                                     FROM TABLE(l_tbl_varchar_aux) t)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_flg_time THEN
                                                                  l_flg_time
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_has_catalogue THEN
                                                                  l_has_catalogue
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_laterality THEN
                                                                  l_laterality_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_to_execute_list THEN
                                                                  l_time_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_frequency THEN
                                                                  decode(l_order_frequency_default, pk_alert_constant.g_no, NULL, to_char(l_order_recurr_desc))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_executions THEN
                                                                  to_char(l_occurrences)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_duration THEN
                                                                  CASE
                                                                      WHEN l_duration IS NOT NULL THEN
                                                                       to_char(l_duration) ||
                                                                       pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                    i_prof         => i_prof,
                                                                                                                    i_unit_measure => l_unit_meas_duration)
                                                                      ELSE
                                                                       NULL
                                                                  END
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_end_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_date, i_prof => i_prof)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_weight_kg THEN
                                                                  l_weight
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_lab_test_result THEN
                                                                  l_analysis_result
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_catalogue THEN
                                                                  l_desc_catalogue_default
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_financial_entity THEN
                                                                  decode(l_id_pat_health_plan,
                                                                         NULL,
                                                                         NULL,
                                                                         pk_adt.get_pat_health_plan_info(i_lang, i_prof, l_id_pat_health_plan, 'F'))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_coverage_plan THEN
                                                                  decode(l_id_pat_health_plan,
                                                                         NULL,
                                                                         NULL,
                                                                         pk_adt.get_pat_health_plan_info(i_lang, i_prof, l_id_pat_health_plan, 'H'))
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_health_plan_number THEN
                                                                  to_char(l_beneficiary_number)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_exemption THEN
                                                                  l_exemption_desc
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => coalesce(def.flg_event_type,
                                                                      CASE
                                                                          WHEN t.internal_name_child IN (pk_orders_constant.g_ds_clinical_indication_mw) THEN
                                                                           CASE l_clinical_indication_mandatory
                                                                               WHEN pk_alert_constant.g_yes THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_active
                                                                           END
                                                                          WHEN t.internal_name_child IN (pk_orders_constant.g_ds_clinical_purpose) THEN
                                                                           CASE l_clinical_purpose_mandatory
                                                                               WHEN pk_alert_constant.g_yes THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_active
                                                                           END
                                                                          WHEN t.internal_name_child IN (pk_orders_constant.g_ds_laterality) THEN
                                                                           CASE i_root_name
                                                                               WHEN pk_orders_constant.g_ds_lab_test_request THEN
                                                                                pk_orders_constant.g_component_hidden
                                                                               ELSE
                                                                                pk_orders_utils.get_laterality_event_type(i_lang                 => i_lang,
                                                                                                                          i_prof                 => i_prof,
                                                                                                                          i_root_name            => i_root_name,
                                                                                                                          i_laterality_mandatory => l_laterality_mandatory,
                                                                                                                          i_idx                  => i_idx,
                                                                                                                          i_value_laterality     => l_flg_laterality,
                                                                                                                          i_tbl_data             => i_tbl_data)
                                                                           END
                                                                          WHEN t.internal_name_child IN
                                                                               (pk_orders_constant.g_ds_duration, pk_orders_constant.g_ds_end_date) THEN
                                                                          --If l_flg_end_by_editable = 'N', fields duration and end date must be inactive
                                                                           decode(l_flg_end_by_editable,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  pk_orders_constant.g_component_inactive)
                                                                          WHEN t.internal_name_child IN (pk_orders_constant.g_ds_executions) THEN
                                                                          --If l_flg_end_by_editable = 'N', field 'Exections' must be Read Only and present the value given by l_occurrences
                                                                           decode(l_flg_end_by_editable,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  pk_orders_constant.g_component_read_only)
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_weight_kg THEN
                                                                           CASE
                                                                               WHEN l_weight IS NULL THEN
                                                                                pk_orders_constant.g_component_inactive
                                                                               ELSE
                                                                                pk_orders_constant.g_component_read_only
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_lab_test_result THEN
                                                                           CASE
                                                                               WHEN l_analysis_result IS NULL THEN
                                                                                pk_orders_constant.g_component_inactive
                                                                               ELSE
                                                                                pk_orders_constant.g_component_read_only
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_execution_ordered_at THEN
                                                                           CASE
                                                                               WHEN l_co_sign_available = pk_alert_constant.g_no THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_hidden
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_scheduling_notes THEN
                                                                           CASE
                                                                               WHEN l_flg_time = pk_alert_constant.g_flg_time_e THEN
                                                                                pk_orders_constant.g_component_inactive
                                                                               ELSE
                                                                                pk_orders_constant.g_component_active
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_notes_technician THEN
                                                                           decode(l_notes_tech_mandatory,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_mandatory,
                                                                                  pk_orders_constant.g_component_active)
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_notes_execution THEN
                                                                           decode(l_notes_execution_mandatory,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_mandatory,
                                                                                  pk_orders_constant.g_component_active)
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_catalogue THEN
                                                                           decode(l_has_catalogue,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  pk_orders_constant.g_component_inactive)
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_financial_entity THEN
                                                                           CASE l_id_market
                                                                               WHEN pk_alert_constant.g_id_market_pt THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_active
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_health_coverage_plan THEN
                                                                           CASE l_id_market
                                                                               WHEN pk_alert_constant.g_id_market_pt THEN
                                                                                pk_orders_constant.g_component_mandatory
                                                                               ELSE
                                                                                pk_orders_constant.g_component_active
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_health_plan_number THEN
                                                                           CASE
                                                                               WHEN l_beneficiary_number IS NOT NULL THEN
                                                                                pk_orders_constant.g_component_read_only
                                                                               ELSE
                                                                                pk_orders_constant.g_component_inactive
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                           CASE
                                                                               WHEN l_flg_time IN (pk_alert_constant.g_flg_time_b, pk_alert_constant.g_flg_time_n) THEN
                                                                                pk_orders_constant.g_component_active
                                                                               ELSE
                                                                                pk_orders_constant.g_component_mandatory
                                                                           END
                                                                          WHEN t.internal_name_child = pk_orders_constant.g_ds_reason_not_ordering THEN
                                                                           decode(l_flg_show_reason_not_order,
                                                                                  pk_alert_constant.g_yes,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  pk_orders_constant.g_component_hidden)
                                                                          ELSE
                                                                           pk_orders_constant.g_component_active
                                                                      END),
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.internal_name IN ( --Clinical indication block
                                       pk_orders_constant.g_ds_clinical_indication_mw,
                                       pk_orders_constant.g_ds_clinical_purpose,
                                       pk_orders_constant.g_ds_laterality,
                                       pk_orders_constant.g_ds_default_laterality,
                                       --Instructions block
                                       pk_orders_constant.g_ds_to_execute_list,
                                       pk_orders_constant.g_ds_frequency,
                                       pk_orders_constant.g_ds_start_date,
                                       pk_orders_constant.g_ds_executions,
                                       pk_orders_constant.g_ds_duration,
                                       pk_orders_constant.g_ds_end_date,
                                       --Execution block
                                       pk_orders_constant.g_ds_execution_ordered_at,
                                       pk_orders_constant.g_ds_weight_kg,
                                       pk_orders_constant.g_ds_lab_test_result,
                                       pk_orders_constant.g_ds_scheduling_notes,
                                       pk_orders_constant.g_ds_reason_not_ordering,
                                       pk_orders_constant.g_ds_notes_technician,
                                       pk_orders_constant.g_ds_notes_execution,
                                       --Health care insurrance block
                                       pk_orders_constant.g_ds_catalogue,
                                       pk_orders_constant.g_ds_health_plan_number,
                                       pk_orders_constant.g_ds_financial_entity,
                                       pk_orders_constant.g_ds_health_coverage_plan,
                                       pk_orders_constant.g_ds_exemption,
                                       --Hidden fields (Memory)
                                       pk_orders_constant.g_ds_root_name,
                                       pk_orders_constant.g_ds_dummy_number, -- this field holds the id_order_recurr_plan
                                       pk_orders_constant.g_ds_flg_edition, --Indicates if it is a new record or an edition
                                       pk_orders_constant.g_ds_tbl_records,
                                       pk_orders_constant.g_ds_flg_time,
                                       pk_orders_constant.g_ds_date_dummy,
                                       pk_orders_constant.g_ds_no_later_than,
                                       pk_orders_constant.g_ds_next_episode_id,
                                       pk_orders_constant.g_ds_has_catalogue)
                  --HIDDEN SECTIONS (CO-SIGN AND HEALTHCARE)
                OR (d.internal_name IN (pk_orders_constant.g_ds_co_sign_control,
                                        pk_orders_constant.g_ds_healthcare_insurance_cat_control,
                                        pk_orders_constant.g_ds_healthcare_insurance_control) AND i_idx = 1)
             ORDER BY t.rn;
        
            --GETTING DEFAULT VALUES FOR ELEMENTS THAT ARE SPECIFIC TO THE ROOT
            IF i_root_name = 'DS_BLOOD_PRODUCTS'
            THEN
                IF NOT pk_orders_utils.get_bp_default_values(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_episode     => i_episode,
                                                             i_patient     => i_patient,
                                                             i_tbl_id_pk   => i_tbl_id_pk,
                                                             i_tbl_mkt_rel => i_tbl_mkt_rel,
                                                             io_tbl_result => tbl_result)
                THEN
                    g_error := 'error found while calling pk_orders_utils.get_bp_default_values function';
                    RAISE g_other_exception;
                END IF;
            ELSIF i_root_name IN (pk_orders_constant.g_ds_lab_test_request)
            THEN
                g_error := 'ERROR CALLING PK_LAB_TESTS_CORE.GET_LAB_TEST_DEFAULT_VALUES';
                IF NOT pk_lab_tests_core.get_lab_test_default_values(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_episode        => i_episode,
                                                                     i_patient        => i_patient,
                                                                     i_action         => i_action,
                                                                     i_root_name      => i_root_name,
                                                                     i_curr_component => i_curr_component,
                                                                     i_idx            => i_idx,
                                                                     i_tbl_id_pk      => i_tbl_id_pk,
                                                                     i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                     i_tbl_int_name   => i_tbl_int_name,
                                                                     i_value          => i_value,
                                                                     i_value_desc     => i_value_desc,
                                                                     i_tbl_data       => i_tbl_data,
                                                                     i_value_clob     => i_value_clob,
                                                                     i_tbl_result     => tbl_result,
                                                                     o_error          => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSIF i_root_name IN
                  (pk_orders_constant.g_ds_imaging_exam_request, pk_orders_constant.g_ds_other_exam_request)
            THEN
                g_error := 'ERROR CALLING PK_EXAM_CORE.GET_EXAM_DEFAULT_VALUES';
                IF NOT pk_exam_core.get_exam_default_values(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_episode        => i_episode,
                                                            i_patient        => i_patient,
                                                            i_action         => i_action,
                                                            i_root_name      => i_root_name,
                                                            i_curr_component => i_curr_component,
                                                            i_idx            => i_idx,
                                                            i_tbl_id_pk      => i_tbl_id_pk,
                                                            i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                            i_tbl_int_name   => i_tbl_int_name,
                                                            i_value          => i_value,
                                                            i_value_desc     => i_value_desc,
                                                            i_tbl_data       => i_tbl_data,
                                                            i_value_clob     => i_value_clob,
                                                            i_tbl_result     => tbl_result,
                                                            o_error          => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSIF i_root_name = pk_orders_constant.g_ds_procedure_request
            THEN
                g_error := 'ERROR CALLING PK_PROCEDURES_CORE.GET_PROCEDURE_DEFAULT_VALUES';
                IF NOT pk_procedures_core.get_procedure_default_values(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_episode        => i_episode,
                                                                       i_patient        => i_patient,
                                                                       i_action         => i_action,
                                                                       i_root_name      => i_root_name,
                                                                       i_curr_component => i_curr_component,
                                                                       i_idx            => i_idx,
                                                                       i_tbl_id_pk      => i_tbl_id_pk,
                                                                       i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                       i_tbl_int_name   => i_tbl_int_name,
                                                                       i_value          => i_value,
                                                                       i_value_desc     => i_value_desc,
                                                                       i_tbl_data       => i_tbl_data,
                                                                       i_value_clob     => i_value_clob,
                                                                       i_tbl_result     => tbl_result,
                                                                       o_error          => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            --Action of submiting a value on any given element of the form
            --IMPORTANT: In order for this action to be executed, a submit action must be configured in ds_event for the given field,
            --otherwise, the i_curr_component is null.
            IF i_curr_component IS NOT NULL
            THEN
                --Check which element has been changed
                SELECT d.internal_name_child
                  INTO l_curr_comp_int_name
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
            
                IF l_curr_comp_int_name = pk_orders_constant.g_ds_prn
                THEN
                    --When changing the PRN value, the fields Frequency, Start date, Executions, Duration 
                    --and End date may change their status (active/inactive)
                    --Also, for each change, the function pk_order_recurrence_api_ux.set_order_recurr_option (for new requests)                    
                    --or pk_order_recurrence_api_ux.edit_order_recurr_plan(for editions) must be called                  
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := i_tbl_int_name(i);
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_tbl_order_recurr_plan.extend();
                            l_tbl_order_recurr_plan(l_tbl_order_recurr_plan.count) := to_number(i_value(i) (1));
                        
                            l_tbl_order_recurr_option.extend();
                            l_tbl_order_recurr_option(l_tbl_order_recurr_option.count) := 0;
                        
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := i_tbl_int_name(j);
                            
                                IF l_ds_internal_name = pk_orders_constant.g_ds_flg_edition
                                THEN
                                    l_flg_edition := i_value(j) (1);
                                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_start_date
                                THEN
                                    l_start_date_str := to_char(i_value(j) (1));
                                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_executions
                                THEN
                                    l_occurrences := to_char(i_value(j) (1));
                                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_duration
                                THEN
                                    l_duration           := to_char(i_value(j) (1));
                                    l_unit_meas_duration := to_number(i_value_mea(j) (1));
                                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
                                THEN
                                    l_end_date_str := to_char(i_value(j) (1));
                                END IF;
                            END LOOP;
                        
                            IF l_flg_edition = pk_alert_constant.g_no
                            THEN
                                IF NOT
                                    pk_order_recurrence_api_ux.set_order_recurr_option(i_lang                => i_lang,
                                                                                       i_prof                => i_prof,
                                                                                       i_order_recurr_plan   => l_tbl_order_recurr_plan,
                                                                                       i_order_recurr_option => l_tbl_order_recurr_option,
                                                                                       o_order_recurr_desc   => l_tbl_order_recurr_desc,
                                                                                       o_order_recurr_option => l_tbl_order_recurr_option,
                                                                                       o_start_date          => l_tbl_start_date,
                                                                                       o_occurrences         => l_tbl_occurrences,
                                                                                       o_duration            => l_tbl_duration,
                                                                                       o_unit_meas_duration  => l_tbl_unit_meas_duration,
                                                                                       o_duration_desc       => l_tbl_duration_desc,
                                                                                       o_end_date            => l_tbl_end_date,
                                                                                       o_flg_end_by_editable => l_tbl_flg_end_by_editable,
                                                                                       o_order_recurr_plan   => l_tbl_order_recurr_plan,
                                                                                       o_error               => o_error)
                                THEN
                                    RAISE g_other_exception;
                                END IF;
                            ELSE
                                l_tbl_order_recurr_desc.extend();
                                l_tbl_order_recurr_option.extend();
                                l_tbl_start_date.extend();
                                l_tbl_occurrences.extend();
                                l_tbl_duration.extend();
                                l_tbl_unit_meas_duration.extend();
                                l_tbl_duration_desc.extend();
                                l_tbl_end_date.extend();
                                l_tbl_flg_end_by_editable.extend();
                            
                                IF NOT
                                    pk_order_recurrence_api_ux.edit_order_recurr_plan(i_lang                   => i_lang,
                                                                                      i_prof                   => i_prof,
                                                                                      i_order_recurr_area      => CASE
                                                                                                                   i_root_name
                                                                                                                      WHEN
                                                                                                                       'DS_BLOOD_PRODUCTS' THEN
                                                                                                                       'BLOOD_PRODUCTS'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_health_education_order THEN
                                                                                                                       'PATIENT_EDUCATION'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                                       'LAB_TEST'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                                       'IMAGE_EXAM'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                                       'OTHER_EXAM'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_procedure_request THEN
                                                                                                                       'PROCEDURE'
                                                                                                                  END,
                                                                                      i_order_recurr_option    => l_tbl_order_recurr_option(1),
                                                                                      i_start_date             => l_start_date_str,
                                                                                      i_occurrences            => l_occurrences,
                                                                                      i_duration               => l_duration,
                                                                                      i_unit_meas_duration     => l_unit_meas_duration,
                                                                                      i_end_date               => l_end_date_str,
                                                                                      i_order_recurr_plan_from => l_tbl_order_recurr_plan(1),
                                                                                      o_order_recurr_desc      => l_tbl_order_recurr_desc(1),
                                                                                      o_order_recurr_option    => l_tbl_order_recurr_option(1),
                                                                                      o_start_date             => l_tbl_start_date(1),
                                                                                      o_occurrences            => l_tbl_occurrences(1),
                                                                                      o_duration               => l_tbl_duration(1),
                                                                                      o_unit_meas_duration     => l_tbl_unit_meas_duration(1),
                                                                                      o_duration_desc          => l_tbl_duration_desc(1),
                                                                                      o_end_date               => l_tbl_end_date(1),
                                                                                      o_flg_end_by_editable    => l_tbl_flg_end_by_editable(1),
                                                                                      o_order_recurr_plan      => l_tbl_order_recurr_plan(1),
                                                                                      o_error                  => o_error)
                                THEN
                                    RAISE g_other_exception;
                                END IF;
                            END IF;
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_prn
                        THEN
                            l_flg_prn := i_value(i) (1);
                        END IF;
                    END LOOP;
                
                    --After obtaining the data from the recurrence apis, it is necessary to fill the related fields
                    --(Frequency/Start date/Execution/Duration/End date)                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := i_tbl_int_name(i);
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_frequency
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_tbl_order_recurr_option(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_tbl_order_recurr_desc(1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_flg_prn
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_read_only
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        ELSIF l_ds_internal_name IN
                              (pk_orders_constant.g_ds_start_date, pk_orders_constant.g_ds_date_dummy)
                        THEN
                            FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                            LOOP
                                IF i_tbl_int_name(j) = pk_orders_constant.g_ds_to_execute_list
                                THEN
                                    l_flg_time := i_value(j) (1);
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => CASE
                                                                                                         WHEN l_flg_time = pk_alert_constant.g_flg_time_n THEN
                                                                                                          NULL
                                                                                                         ELSE
                                                                                                          l_tbl_start_date(1)
                                                                                                     END,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_ds_internal_name
                                                                                                         WHEN pk_orders_constant.g_ds_date_dummy THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          CASE l_flg_prn
                                                                                                              WHEN pk_alert_constant.g_yes THEN
                                                                                                               pk_orders_constant.g_component_read_only
                                                                                                              ELSE
                                                                                                               CASE
                                                                                                                   WHEN l_flg_time = pk_alert_constant.g_flg_time_b THEN
                                                                                                                    pk_orders_constant.g_component_active
                                                                                                                   WHEN l_flg_time = pk_alert_constant.g_flg_time_n THEN
                                                                                                                    pk_orders_constant.g_component_inactive
                                                                                                                   ELSE
                                                                                                                    pk_orders_constant.g_component_mandatory
                                                                                                               END
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_executions
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_tbl_occurrences(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_tbl_occurrences(1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_flg_prn
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_read_only
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN l_tbl_flg_end_by_editable(1) = pk_alert_constant.g_yes THEN
                                                                                                               pk_orders_constant.g_component_active
                                                                                                              ELSE
                                                                                                               pk_orders_constant.g_component_read_only
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_duration
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_tbl_duration(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => CASE
                                                                                                         WHEN l_tbl_duration_desc(1) IS NOT NULL THEN
                                                                                                          l_tbl_duration_desc(1) || ' ' ||
                                                                                                          pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                                                                       i_prof,
                                                                                                                                                       l_tbl_unit_meas_duration(1))
                                                                                                     END,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => l_tbl_unit_meas_duration(1),
                                                                               desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                                                                  i_prof,
                                                                                                                                                  l_tbl_unit_meas_duration(1)),
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_tbl_flg_end_by_editable(1) = pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_end_date
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_tbl_end_date(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_tbl_flg_end_by_editable(1) = pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_tbl_order_recurr_plan(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name IN (pk_orders_constant.g_ds_frequency,
                                               pk_orders_constant.g_ds_other_frequency,
                                               pk_orders_constant.g_ds_start_date,
                                               pk_orders_constant.g_ds_executions,
                                               pk_orders_constant.g_ds_duration,
                                               pk_orders_constant.g_ds_end_date,
                                               pk_orders_constant.g_ds_to_execute_list)
                THEN
                    --Obtain the id order recurr plan which is stored in DS_DUMMY_NUMBER element
                    --DS_DUMMY_NUMBER is an hidden field of the form. The reccurence id is stored in this element
                    --when the form is initialized
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_tbl_order_recurr_plan.extend();
                            l_tbl_order_recurr_plan(l_tbl_order_recurr_plan.count) := to_number(i_value(i) (1));
                        
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF i_tbl_int_name(j) = pk_orders_constant.g_ds_flg_edition
                                THEN
                                    l_flg_edition := i_value(j) (1);
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_frequency
                                THEN
                                    l_order_recurr_option := to_number(i_value(j) (1));
                                
                                    l_tbl_order_recurr_option.extend();
                                    l_tbl_order_recurr_option(l_tbl_order_recurr_option.count) := to_number(i_value(j) (1));
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_start_date
                                      AND l_curr_comp_int_name <> pk_orders_constant.g_ds_to_execute_list
                                THEN
                                    l_start_date_str := to_char(i_value(j) (1));
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_start_date
                                      AND l_curr_comp_int_name = pk_orders_constant.g_ds_to_execute_list
                                THEN
                                    SELECT pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                       i_date => orp.start_date,
                                                                       i_inst => i_prof.institution,
                                                                       i_soft => i_prof.software)
                                      INTO l_start_date_str
                                      FROM order_recurr_plan orp
                                     WHERE orp.id_order_recurr_plan =
                                           l_tbl_order_recurr_plan(l_tbl_order_recurr_plan.count);
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_executions
                                THEN
                                    l_occurrences := to_char(i_value(j) (1));
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_duration
                                THEN
                                    l_duration           := to_char(i_value(j) (1));
                                    l_unit_meas_duration := to_number(i_value_mea(j) (1));
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_end_date
                                THEN
                                    l_end_date_str := to_char(i_value(j) (1));
                                END IF;
                            END LOOP;
                        
                            IF l_flg_edition = pk_alert_constant.g_no
                            THEN
                                IF l_curr_comp_int_name IN
                                   (pk_orders_constant.g_ds_frequency, pk_orders_constant.g_ds_other_frequency)
                                THEN
                                    IF l_order_recurr_option <> -1 --When frequency is not set as 'Other frequency'
                                    THEN
                                        IF NOT
                                            pk_order_recurrence_api_ux.set_order_recurr_option(i_lang                => i_lang,
                                                                                               i_prof                => i_prof,
                                                                                               i_order_recurr_plan   => l_tbl_order_recurr_plan,
                                                                                               i_order_recurr_option => l_tbl_order_recurr_option,
                                                                                               o_order_recurr_desc   => l_tbl_order_recurr_desc,
                                                                                               o_order_recurr_option => l_tbl_order_recurr_option,
                                                                                               o_start_date          => l_tbl_start_date,
                                                                                               o_occurrences         => l_tbl_occurrences,
                                                                                               o_duration            => l_tbl_duration,
                                                                                               o_unit_meas_duration  => l_tbl_unit_meas_duration,
                                                                                               o_duration_desc       => l_tbl_duration_desc,
                                                                                               o_end_date            => l_tbl_end_date,
                                                                                               o_flg_end_by_editable => l_tbl_flg_end_by_editable,
                                                                                               o_order_recurr_plan   => l_tbl_order_recurr_plan,
                                                                                               o_error               => o_error)
                                        THEN
                                            RAISE g_other_exception;
                                        END IF;
                                    ELSE
                                        --Frequency set as 'Other frequency'
                                        l_tbl_order_recurr_desc.extend();
                                        l_tbl_order_recurr_option.extend();
                                        l_tbl_start_date.extend();
                                        l_tbl_occurrences.extend();
                                        l_tbl_duration.extend();
                                        l_tbl_unit_meas_duration.extend();
                                        l_tbl_duration_desc.extend();
                                        l_tbl_end_date.extend();
                                        l_tbl_flg_end_by_editable.extend();
                                    
                                        IF NOT
                                            pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                                   i_prof                => i_prof,
                                                                                                   i_order_plan          => l_tbl_order_recurr_plan(1),
                                                                                                   o_order_recurr_desc   => l_tbl_order_recurr_desc(1),
                                                                                                   o_order_recurr_option => l_tbl_order_recurr_option(1),
                                                                                                   o_start_date          => l_start_date,
                                                                                                   o_occurrences         => l_tbl_occurrences(1),
                                                                                                   o_duration            => l_tbl_duration(1),
                                                                                                   o_unit_meas_duration  => l_tbl_unit_meas_duration(1),
                                                                                                   o_end_date            => l_end_date,
                                                                                                   o_flg_end_by_editable => l_tbl_flg_end_by_editable(1),
                                                                                                   o_error               => o_error)
                                        THEN
                                            g_error := 'error while calling get_order_recurr_instructions function';
                                            RAISE g_other_exception;
                                        END IF;
                                    
                                        --Function pk_order_recurrence_core.get_order_recurr_instructions returns the dates as timestamp
                                        --It is necessary to convert them as string
                                        l_tbl_start_date(1) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                           i_date => l_start_date,
                                                                                           i_prof => i_prof);
                                        l_tbl_end_date(1) := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                         i_date => l_end_date,
                                                                                         i_prof => i_prof);
                                    
                                        FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                                        LOOP
                                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_frequency
                                            THEN
                                                l_order_recurr_option := to_number(i_value(j) (1));
                                                l_order_recurr_desc   := i_value_desc(j) (1);
                                            END IF;
                                        END LOOP;
                                    END IF;
                                ELSE
                                    l_tbl_order_recurr_desc.extend();
                                    l_tbl_order_recurr_option.extend();
                                    l_tbl_start_date.extend();
                                    l_tbl_occurrences.extend();
                                    l_tbl_duration.extend();
                                    l_tbl_unit_meas_duration.extend();
                                    l_tbl_duration_desc.extend();
                                    l_tbl_end_date.extend();
                                    l_tbl_flg_end_by_editable.extend();
                                    l_tbl_order_recurr_plan.extend();
                                
                                    IF NOT
                                        pk_order_recurrence_api_ux.set_order_recurr_instructions(i_lang                => i_lang,
                                                                                                 i_prof                => i_prof,
                                                                                                 i_order_recurr_plan   => l_tbl_order_recurr_plan(1),
                                                                                                 i_start_date          => l_start_date_str,
                                                                                                 i_occurrences         => CASE
                                                                                                                           l_curr_comp_int_name
                                                                                                                              WHEN
                                                                                                                               pk_orders_constant.g_ds_executions THEN
                                                                                                                               l_occurrences
                                                                                                                          END,
                                                                                                 i_duration            => CASE
                                                                                                                           l_curr_comp_int_name
                                                                                                                              WHEN
                                                                                                                               pk_orders_constant.g_ds_duration THEN
                                                                                                                               l_duration
                                                                                                                          END,
                                                                                                 i_unit_meas_duration  => CASE
                                                                                                                           l_curr_comp_int_name
                                                                                                                              WHEN
                                                                                                                               pk_orders_constant.g_ds_duration THEN
                                                                                                                               l_unit_meas_duration
                                                                                                                          END,
                                                                                                 i_end_date            => CASE
                                                                                                                           l_curr_comp_int_name
                                                                                                                              WHEN
                                                                                                                               pk_orders_constant.g_ds_end_date THEN
                                                                                                                               l_end_date_str
                                                                                                                          END,
                                                                                                 o_order_recurr_desc   => l_tbl_order_recurr_desc(1),
                                                                                                 o_order_recurr_option => l_tbl_order_recurr_option(1),
                                                                                                 o_start_date          => l_tbl_start_date(1),
                                                                                                 o_occurrences         => l_tbl_occurrences(1),
                                                                                                 o_duration            => l_tbl_duration(1),
                                                                                                 o_unit_meas_duration  => l_tbl_unit_meas_duration(1),
                                                                                                 o_duration_desc       => l_tbl_duration_desc(1),
                                                                                                 o_end_date            => l_tbl_end_date(1),
                                                                                                 o_flg_end_by_editable => l_tbl_flg_end_by_editable(1),
                                                                                                 o_order_recurr_plan   => l_tbl_order_recurr_plan(1),
                                                                                                 o_error               => o_error)
                                    THEN
                                        RAISE g_other_exception;
                                    END IF;
                                END IF;
                            ELSE
                                l_tbl_order_recurr_desc.extend();
                                l_tbl_order_recurr_option.extend();
                                l_tbl_start_date.extend();
                                l_tbl_occurrences.extend();
                                l_tbl_duration.extend();
                                l_tbl_unit_meas_duration.extend();
                                l_tbl_duration_desc.extend();
                                l_tbl_end_date.extend();
                                l_tbl_flg_end_by_editable.extend();
                            
                                IF NOT
                                    pk_order_recurrence_api_ux.edit_order_recurr_plan(i_lang                   => i_lang,
                                                                                      i_prof                   => i_prof,
                                                                                      i_order_recurr_area      => CASE
                                                                                                                   i_root_name
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                                       'LAB_TEST'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                                       'IMAGE_EXAM'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                                       'OTHER_EXAM'
                                                                                                                      WHEN
                                                                                                                       pk_orders_constant.g_ds_procedure_request THEN
                                                                                                                       'PROCEDURE'
                                                                                                                  END,
                                                                                      i_order_recurr_option    => l_tbl_order_recurr_option(1),
                                                                                      i_start_date             => l_start_date_str,
                                                                                      i_occurrences            => l_occurrences,
                                                                                      i_duration               => l_duration,
                                                                                      i_unit_meas_duration     => l_unit_meas_duration,
                                                                                      i_end_date               => l_end_date_str,
                                                                                      i_order_recurr_plan_from => l_tbl_order_recurr_plan(1),
                                                                                      o_order_recurr_desc      => l_tbl_order_recurr_desc(1),
                                                                                      o_order_recurr_option    => l_tbl_order_recurr_option(1),
                                                                                      o_start_date             => l_tbl_start_date(1),
                                                                                      o_occurrences            => l_tbl_occurrences(1),
                                                                                      o_duration               => l_tbl_duration(1),
                                                                                      o_unit_meas_duration     => l_tbl_unit_meas_duration(1),
                                                                                      o_duration_desc          => l_tbl_duration_desc(1),
                                                                                      o_end_date               => l_tbl_end_date(1),
                                                                                      o_flg_end_by_editable    => l_tbl_flg_end_by_editable(1),
                                                                                      o_order_recurr_plan      => l_tbl_order_recurr_plan(1),
                                                                                      o_error                  => o_error)
                                THEN
                                    RAISE g_other_exception;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := i_tbl_int_name(i);
                    
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_other_frequency
                           AND l_order_recurr_option = -1
                           AND l_curr_comp_int_name <> pk_orders_constant.g_ds_frequency
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => l_tbl_order_recurr_option(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_tbl_order_recurr_desc(1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_other_frequency
                              AND l_curr_comp_int_name = pk_orders_constant.g_ds_frequency
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => NULL,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_order_recurr_option = -1 THEN
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF i_tbl_int_name(i) IN
                              (pk_orders_constant.g_ds_start_date, pk_orders_constant.g_ds_date_dummy)
                        THEN
                            --If the current_component is the 'To_execute' field, the value receiveid in i_value will be piped (flg_time,id_next_episode,no_later_than)
                            --because it wil be comming from the Episode modal window
                            --In that case, it is not possible to read directly from the i_value, it is rather necessary
                            --to parse its value using pk_string_utils.str_split
                            IF l_curr_comp_int_name <> pk_orders_constant.g_ds_to_execute_list
                            THEN
                                FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                                LOOP
                                    IF i_tbl_int_name(j) = pk_orders_constant.g_ds_to_execute_list
                                    THEN
                                        l_flg_time := i_value(j) (1);
                                        EXIT;
                                    END IF;
                                END LOOP;
                            ELSE
                                FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                                LOOP
                                    IF i_tbl_int_name(j) = pk_orders_constant.g_ds_to_execute_list
                                    THEN
                                        l_tbl_flg_time := table_varchar();
                                        IF i_value(j) (1) IS NOT NULL
                                        THEN
                                            l_tbl_flg_time := pk_string_utils.str_split(i_list  => i_value(j) (1),
                                                                                        i_delim => '|');
                                        ELSE
                                            l_tbl_flg_time := table_varchar(NULL);
                                        END IF;
                                    
                                        l_flg_time := l_tbl_flg_time(i_idx);
                                        EXIT;
                                    END IF;
                                END LOOP;
                            END IF;
                        
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            IF l_curr_comp_int_name <> pk_orders_constant.g_ds_start_date
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => CASE
                                                                                                             WHEN l_flg_time = pk_alert_constant.g_flg_time_n THEN
                                                                                                              NULL
                                                                                                             ELSE
                                                                                                              l_tbl_start_date(1)
                                                                                                         END,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE l_ds_internal_name
                                                                                                             WHEN pk_orders_constant.g_ds_date_dummy THEN
                                                                                                              pk_orders_constant.g_component_active
                                                                                                             ELSE
                                                                                                              CASE l_flg_prn
                                                                                                                  WHEN pk_alert_constant.g_yes THEN
                                                                                                                   pk_orders_constant.g_component_read_only
                                                                                                                  ELSE
                                                                                                                   CASE
                                                                                                                       WHEN l_flg_time = pk_alert_constant.g_flg_time_b THEN
                                                                                                                        pk_orders_constant.g_component_active
                                                                                                                       WHEN l_flg_time = pk_alert_constant.g_flg_time_n THEN
                                                                                                                        pk_orders_constant.g_component_inactive
                                                                                                                       ELSE
                                                                                                                        pk_orders_constant.g_component_mandatory
                                                                                                                   END
                                                                                                              END
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            ELSE
                                SELECT e.dt_begin_tstz
                                  INTO l_dt_epis_begin
                                  FROM episode e
                                 WHERE e.id_episode = i_episode;
                            
                                l_epis_begin_verification := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                                             i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                                         i_timestamp => l_dt_epis_begin,
                                                                                                                                         i_format    => 'MI'),
                                                                                             i_date2 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                                         i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                                      i_prof,
                                                                                                                                                                                      l_tbl_start_date(1),
                                                                                                                                                                                      NULL),
                                                                                                                                         i_format    => 'MI'));
                            
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => CASE l_epis_begin_verification
                                                                                                             WHEN 'G' THEN
                                                                                                              NULL
                                                                                                             ELSE
                                                                                                              l_tbl_start_date(1)
                                                                                                         END,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => CASE l_epis_begin_verification
                                                                                                             WHEN 'G' THEN
                                                                                                              pk_orders_constant.g_component_error
                                                                                                             ELSE
                                                                                                              pk_orders_constant.g_component_valid
                                                                                                         END,
                                                                                   err_msg            => CASE l_epis_begin_verification
                                                                                                             WHEN 'G' THEN
                                                                                                              pk_message.get_message(i_lang,
                                                                                                                                     'COMMON_M166')
                                                                                                         END,
                                                                                   flg_event_type     => CASE l_ds_internal_name
                                                                                                             WHEN pk_orders_constant.g_ds_date_dummy THEN
                                                                                                              pk_orders_constant.g_component_active
                                                                                                             ELSE
                                                                                                              CASE l_flg_prn
                                                                                                                  WHEN pk_alert_constant.g_yes THEN
                                                                                                                   pk_orders_constant.g_component_read_only
                                                                                                                  ELSE
                                                                                                                   CASE
                                                                                                                       WHEN l_flg_time = pk_alert_constant.g_flg_time_b THEN
                                                                                                                        pk_orders_constant.g_component_active
                                                                                                                       WHEN l_flg_time = pk_alert_constant.g_flg_time_n THEN
                                                                                                                        pk_orders_constant.g_component_inactive
                                                                                                                       ELSE
                                                                                                                        pk_orders_constant.g_component_mandatory
                                                                                                                   END
                                                                                                              END
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_executions
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => l_tbl_occurrences(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_tbl_occurrences(1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_flg_prn
                                                                                                         WHEN pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_read_only
                                                                                                         ELSE
                                                                                                          CASE
                                                                                                              WHEN l_tbl_flg_end_by_editable(1) = pk_alert_constant.g_yes THEN
                                                                                                               pk_orders_constant.g_component_active
                                                                                                              ELSE
                                                                                                               pk_orders_constant.g_component_read_only
                                                                                                          END
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_duration
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => l_tbl_duration(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => CASE
                                                                                                         WHEN l_tbl_duration(1) IS NOT NULL THEN
                                                                                                          l_tbl_duration(1) || ' ' ||
                                                                                                          pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                                                                       i_prof,
                                                                                                                                                       l_tbl_unit_meas_duration(1))
                                                                                                     END,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => l_tbl_unit_meas_duration(1),
                                                                               desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                                                                  i_prof,
                                                                                                                                                  l_tbl_unit_meas_duration(1)),
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_tbl_flg_end_by_editable(1) = pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_end_date
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => l_tbl_end_date(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_tbl_flg_end_by_editable(1) = pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_to_execute_list
                              AND l_curr_comp_int_name = pk_orders_constant.g_ds_to_execute_list
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            l_tbl_flg_time := table_varchar();
                            IF i_value(i) (1) IS NOT NULL
                            THEN
                                l_tbl_flg_time := pk_string_utils.str_split(i_list => i_value(i) (1), i_delim => '|');
                            ELSE
                                l_tbl_flg_time := table_varchar(NULL);
                            END IF;
                        
                            IF l_tbl_flg_time(i_idx) <> pk_alert_constant.g_flg_time_n
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => l_tbl_flg_time(i_idx),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => pk_sysdomain.get_domain(i_code_dom => CASE
                                                                                                                                                i_root_name
                                                                                                                                                   WHEN
                                                                                                                                                    pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                                                                    'ANALYSIS_REQ_DET.FLG_TIME_HARVEST'
                                                                                                                                                   WHEN
                                                                                                                                                    pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                                                                    'EXAM_REQ.FLG_TIME'
                                                                                                                                                   WHEN
                                                                                                                                                    pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                                                                    'EXAM_REQ.FLG_TIME'
                                                                                                                                                   WHEN
                                                                                                                                                    pk_orders_constant.g_ds_procedure_request THEN
                                                                                                                                                    'INTERV_PRESCRIPTION.FLG_TIME'
                                                                                                                                               END,
                                                                                                                                 i_val      => l_tbl_flg_time(i_idx),
                                                                                                                                 i_lang     => i_lang),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        
                            FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                l_ds_internal_name := i_tbl_int_name(j);
                            
                                IF i_tbl_int_name(j) = pk_orders_constant.g_ds_flg_time
                                THEN
                                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                                
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => i_tbl_int_name(j),
                                                                                       VALUE              => l_tbl_flg_time(i_idx),
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => NULL,
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_next_episode_id
                                THEN
                                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                                
                                    l_tbl_next_episode := table_varchar();
                                    IF i_value(i) (2) IS NOT NULL
                                    THEN
                                        l_tbl_next_episode := pk_string_utils.str_split(i_list  => i_value(i) (2),
                                                                                        i_delim => '|');
                                    ELSE
                                        l_tbl_next_episode := table_varchar(NULL);
                                    END IF;
                                
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => i_tbl_int_name(j),
                                                                                       VALUE              => l_tbl_next_episode(i_idx),
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => NULL,
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                                
                                    IF l_tbl_flg_time(i_idx) = pk_alert_constant.g_flg_time_n
                                    THEN
                                        l_id_epis_to_execute := to_number(l_tbl_next_episode(i_idx));
                                    
                                        IF l_id_epis_to_execute IS NOT NULL
                                        THEN
                                            g_error := 'GETTING EPISODE TO EXECUTE DESC';
                                            SELECT /*+opt_estimate (table t rows=1)*/
                                             t.event_type_name_title || ': ' || t.event_type_clinical_service || '; ' ||
                                             (SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
                                                FROM sch_event se
                                               WHERE se.id_sch_event = t.sch_event) || '; ' || t.professional
                                              INTO l_epis_to_execute_desc
                                              FROM TABLE(pk_events.get_patient_future_events_pl(i_lang,
                                                                                                i_prof,
                                                                                                i_patient)) t
                                             WHERE t.id_episode = l_id_epis_to_execute;
                                        END IF;
                                    
                                        l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                                    
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                           id_ds_component    => l_id_ds_component,
                                                                                           internal_name      => i_tbl_int_name(i),
                                                                                           VALUE              => l_tbl_flg_time(i_idx),
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => l_epis_to_execute_desc,
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END IF;
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_no_later_than
                                THEN
                                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                                
                                    l_tbl_no_later_than := table_varchar();
                                    IF i_value(i) (3) IS NOT NULL
                                    THEN
                                        l_tbl_no_later_than := pk_string_utils.str_split(i_list  => i_value(i) (3),
                                                                                         i_delim => '|');
                                    ELSE
                                        l_tbl_no_later_than := table_varchar(NULL);
                                    END IF;
                                
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => i_tbl_int_name(j),
                                                                                       VALUE              => l_tbl_no_later_than(i_idx),
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => NULL,
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => pk_orders_constant.g_component_active,
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_scheduling_notes
                                THEN
                                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j));
                                
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                       id_ds_component    => l_id_ds_component,
                                                                                       internal_name      => i_tbl_int_name(j),
                                                                                       VALUE              => i_value(j) (1),
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => i_value_desc(j) (1),
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => CASE
                                                                                                              l_tbl_flg_time(i_idx)
                                                                                                                 WHEN
                                                                                                                  pk_alert_constant.g_flg_time_e THEN
                                                                                                                  pk_orders_constant.g_component_inactive
                                                                                                                 ELSE
                                                                                                                  pk_orders_constant.g_component_active
                                                                                                             END,
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                                END IF;
                            END LOOP;
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_tbl_order_recurr_plan(1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_order_type
                THEN
                    IF NOT pk_orders_utils.get_co_sign_values(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_episode      => i_episode,
                                                              i_patient      => i_patient,
                                                              i_root_name    => i_root_name,
                                                              i_idx          => i_idx,
                                                              i_tbl_id_pk    => i_tbl_id_pk,
                                                              i_tbl_mkt_rel  => i_tbl_mkt_rel,
                                                              i_tbl_int_name => i_tbl_int_name,
                                                              i_value        => i_value,
                                                              i_value_mea    => i_value_mea,
                                                              i_value_desc   => i_value_desc,
                                                              i_tbl_data     => i_tbl_data,
                                                              i_value_clob   => i_value_clob,
                                                              i_tbl_result   => tbl_result,
                                                              o_error        => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_health_coverage_plan
                THEN
                    FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        IF i_tbl_int_name(j) IN (pk_orders_constant.g_ds_health_coverage_plan)
                        THEN
                            l_id_health_coverage_plan := i_value(j) (1);
                        END IF;
                    END LOOP;
                
                    FOR j IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        IF i_tbl_int_name(j) IN (pk_orders_constant.g_ds_financial_entity)
                        THEN
                            l_id_financial_entity := i_value(j) (1);
                            IF l_id_financial_entity IS NULL
                               AND l_id_health_coverage_plan IS NOT NULL
                            THEN
                                SELECT hpe.id_health_plan_entity
                                  INTO l_id_financial_entity
                                  FROM pat_health_plan php
                                  JOIN health_plan hp
                                    ON php.id_health_plan = hp.id_health_plan
                                  LEFT JOIN health_plan_entity hpe
                                    ON hp.id_health_plan_entity = hpe.id_health_plan_entity
                                 WHERE php.id_pat_health_plan = l_id_health_coverage_plan;
                            END IF;
                        END IF;
                    END LOOP;
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        IF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_health_plan_number)
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            l_beneficiary_number := pk_orders_utils.get_patient_beneficiary_number(i_lang               => i_lang,
                                                                                                   i_prof               => i_prof,
                                                                                                   i_patient            => i_patient,
                                                                                                   i_health_plan_entity => l_id_financial_entity,
                                                                                                   i_health_plan        => l_id_health_coverage_plan);
                            IF l_beneficiary_number IS NOT NULL
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => l_beneficiary_number,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => l_beneficiary_number,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_read_only,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            ELSE
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_inactive,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_financial_entity
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => to_char(l_id_financial_entity),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => pk_adt.get_pat_health_plan_info(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     l_id_health_coverage_plan,
                                                                                                                                     'F'),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_id_market
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_id_market_pt THEN
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_active
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_financial_entity
                THEN
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        IF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_health_coverage_plan)
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => NULL,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_id_market
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_id_market_pt THEN
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_active
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_health_plan_number)
                        THEN
                            l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => NULL,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_inactive,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_supply_order_mw
                THEN
                    /*The UX will send all the information necessary for the supplies in this field
                    The info is sent in an array and will have the following structure:
                    [0]: ID_SUPPLY 
                    [1]: ID_SET
                    [2]: QUANTITY
                    [3]: DT_RETURN
                    [4]: SUPPLY_LOCATION
                    
                    Each element will carry the info for all the supplies selected on the supplies modal, and are separated by a pipe.
                    For instances, the array will be something like this:
                      [ID_SUPPLY_1|ID_SUPPLY_2, ID_SET_1|ID_SET_2, QUANTITY_1|QUANTITY_2, DT_RETURN_1|DT_RETURN_2, SUPPLY_LOCATION_1|SUPPLY_LOCATION2]
                    
                    This submit action has to fetch all that information and inject it in the respective memory fields.
                    
                    The value of pk_orders_constant.g_ds_supply_order_mw should not be changed, because it will be used by the supplies modal
                    if the user wants to access the grid again.
                    */
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_supply_order_mw
                        THEN
                            --When clearing the field, the array will not have all elements, and in this case, we should erase the memory fields
                            IF i_value(i).count = 5
                            THEN
                                l_tbl_supply     := pk_string_utils.str_split(i_list => i_value(i) (1), i_delim => '|');
                                l_tbl_set        := pk_string_utils.str_split(i_list => i_value(i) (2), i_delim => '|');
                                l_tbl_quantity   := pk_string_utils.str_split(i_list => i_value(i) (3), i_delim => '|');
                                l_tbl_dt_return  := pk_string_utils.str_split(i_list => i_value(i) (4), i_delim => '|');
                                l_tbl_supply_loc := pk_string_utils.str_split(i_list => i_value(i) (5), i_delim => '|');
                            END IF;
                        
                            IF l_tbl_supply.exists(1)
                            THEN
                                SELECT pk_translation.get_translation(i_lang, s.code_supply) || '(' || tbl_qty.quantity || ')'
                                  BULK COLLECT
                                  INTO l_tbl_supply_desc
                                  FROM supply s
                                  JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                                         to_number(t.column_value) id_supply, rownum AS rn
                                          FROM TABLE(l_tbl_supply) t) tbl_sup
                                    ON tbl_sup.id_supply = s.id_supply
                                  LEFT JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                                              to_number(t.column_value) quantity, rownum AS rn
                                               FROM TABLE(l_tbl_quantity) t) tbl_qty
                                    ON tbl_qty.rn = tbl_sup.rn;
                            
                                FOR j IN l_tbl_supply_desc.first .. l_tbl_supply_desc.last
                                LOOP
                                    l_supply_desc := l_supply_desc || l_tbl_supply_desc(j) || CASE
                                                         WHEN l_tbl_supply_desc.first = l_tbl_supply_desc.last
                                                              OR j = l_tbl_supply_desc.last THEN
                                                          '.'
                                                         ELSE
                                                          '; '
                                                     END;
                                END LOOP;
                            
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i)),
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => i_value(i)
                                                                                                         (1) || ',' ||
                                                                                                         i_value(i)
                                                                                                         (2) || ',' ||
                                                                                                         i_value(i)
                                                                                                         (3) || ',' ||
                                                                                                         i_value(i)
                                                                                                         (4) || ',' ||
                                                                                                         i_value(i) (5),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => l_supply_desc,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_unique,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            ELSE
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i)),
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_unique,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        
                            --Set the Memory fields                                          
                            FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                            LOOP
                                IF i_tbl_int_name(j) = pk_orders_constant.g_ds_id_supply
                                THEN
                                    IF l_tbl_supply.exists(1)
                                    THEN
                                        FOR k IN l_tbl_supply.first .. l_tbl_supply.last
                                        LOOP
                                            tbl_result.extend();
                                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                               internal_name      => i_tbl_int_name(j),
                                                                                               VALUE              => l_tbl_supply(k),
                                                                                               value_clob         => NULL,
                                                                                               min_value          => NULL,
                                                                                               max_value          => NULL,
                                                                                               desc_value         => NULL,
                                                                                               desc_clob          => NULL,
                                                                                               id_unit_measure    => NULL,
                                                                                               desc_unit_measure  => NULL,
                                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                                               err_msg            => NULL,
                                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                                               flg_multi_status   => NULL,
                                                                                               idx                => i_idx);
                                        END LOOP;
                                    ELSE
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                           internal_name      => i_tbl_int_name(j),
                                                                                           VALUE              => NULL,
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => NULL,
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END IF;
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_supply_set
                                THEN
                                    IF l_tbl_set.exists(1)
                                    THEN
                                        FOR k IN l_tbl_set.first .. l_tbl_set.last
                                        LOOP
                                            tbl_result.extend();
                                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                               internal_name      => i_tbl_int_name(j),
                                                                                               VALUE              => to_char(coalesce(l_tbl_set(k),
                                                                                                                                      -1)),
                                                                                               value_clob         => NULL,
                                                                                               min_value          => NULL,
                                                                                               max_value          => NULL,
                                                                                               desc_value         => NULL,
                                                                                               desc_clob          => NULL,
                                                                                               id_unit_measure    => NULL,
                                                                                               desc_unit_measure  => NULL,
                                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                                               err_msg            => NULL,
                                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                                               flg_multi_status   => NULL,
                                                                                               idx                => i_idx);
                                        END LOOP;
                                    ELSE
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                           internal_name      => i_tbl_int_name(j),
                                                                                           VALUE              => '-1',
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => NULL,
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END IF;
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_supply_quantity
                                THEN
                                    IF l_tbl_quantity.exists(1)
                                    THEN
                                        FOR k IN l_tbl_quantity.first .. l_tbl_quantity.last
                                        LOOP
                                            tbl_result.extend();
                                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                               internal_name      => i_tbl_int_name(j),
                                                                                               VALUE              => to_char(coalesce(l_tbl_quantity(k),
                                                                                                                                      -1)),
                                                                                               value_clob         => NULL,
                                                                                               min_value          => NULL,
                                                                                               max_value          => NULL,
                                                                                               desc_value         => NULL,
                                                                                               desc_clob          => NULL,
                                                                                               id_unit_measure    => NULL,
                                                                                               desc_unit_measure  => NULL,
                                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                                               err_msg            => NULL,
                                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                                               flg_multi_status   => NULL,
                                                                                               idx                => i_idx);
                                        END LOOP;
                                    ELSE
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                           internal_name      => i_tbl_int_name(j),
                                                                                           VALUE              => '-1',
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => NULL,
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END IF;
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_supply_dt_return
                                THEN
                                    IF l_tbl_dt_return.exists(1)
                                    THEN
                                        FOR k IN l_tbl_dt_return.first .. l_tbl_dt_return.last
                                        LOOP
                                            tbl_result.extend();
                                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                               internal_name      => i_tbl_int_name(j),
                                                                                               VALUE              => to_char(coalesce(l_tbl_dt_return(k),
                                                                                                                                      '-1')),
                                                                                               value_clob         => NULL,
                                                                                               min_value          => NULL,
                                                                                               max_value          => NULL,
                                                                                               desc_value         => NULL,
                                                                                               desc_clob          => NULL,
                                                                                               id_unit_measure    => NULL,
                                                                                               desc_unit_measure  => NULL,
                                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                                               err_msg            => NULL,
                                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                                               flg_multi_status   => NULL,
                                                                                               idx                => i_idx);
                                        END LOOP;
                                    ELSE
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                           internal_name      => i_tbl_int_name(j),
                                                                                           VALUE              => '-1',
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => NULL,
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END IF;
                                ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_supply_location
                                THEN
                                    IF l_tbl_supply_loc.exists(1)
                                    THEN
                                        FOR k IN l_tbl_supply_loc.first .. l_tbl_supply_loc.last
                                        LOOP
                                            tbl_result.extend();
                                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                               internal_name      => i_tbl_int_name(j),
                                                                                               VALUE              => coalesce(l_tbl_supply_loc(k),
                                                                                                                              '-1'),
                                                                                               value_clob         => NULL,
                                                                                               min_value          => NULL,
                                                                                               max_value          => NULL,
                                                                                               desc_value         => NULL,
                                                                                               desc_clob          => NULL,
                                                                                               id_unit_measure    => NULL,
                                                                                               desc_unit_measure  => NULL,
                                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                                               err_msg            => NULL,
                                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                                               flg_multi_status   => NULL,
                                                                                               idx                => i_idx);
                                        END LOOP;
                                    ELSE
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(j),
                                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(j)),
                                                                                           internal_name      => i_tbl_int_name(j),
                                                                                           VALUE              => '-1',
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => NULL,
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => i_idx);
                                    END IF;
                                END IF;
                            END LOOP;
                        
                            --Exit the cicle, it isn't necessary to continue.
                            EXIT;
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_execution_ordered_at
                THEN
                    --Check if it is a valid date
                    l_varchar_aux := pk_orders_utils.get_value(i_internal_name_child => l_curr_comp_int_name,
                                                               i_tbl_mkt_rel         => i_tbl_mkt_rel,
                                                               i_value               => i_value);
                
                    IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_id_episode    => i_episode,
                                                             o_dt_begin_tstz => l_dt_epis_begin,
                                                             o_error         => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    l_date_comparison := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                         i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                     i_timestamp => l_dt_epis_begin,
                                                                                                                     i_format    => 'MI'),
                                                                         i_date2 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                     i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                  i_prof,
                                                                                                                                                                  l_varchar_aux,
                                                                                                                                                                  NULL),
                                                                                                                     i_format    => 'MI'));
                
                    IF l_date_comparison = 'G'
                    THEN
                        tbl_result.extend();
                        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => d.id_ds_cmpt_mkt_rel,
                                                  id_ds_component    => d.id_ds_component_child,
                                                  internal_name      => d.internal_name_child,
                                                  VALUE              => l_varchar_aux,
                                                  value_clob         => NULL,
                                                  min_value          => NULL,
                                                  max_value          => NULL,
                                                  desc_value         => NULL,
                                                  desc_clob          => NULL,
                                                  id_unit_measure    => d.id_unit_measure,
                                                  desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                     i_prof         => i_prof,
                                                                                                                     i_unit_measure => d.id_unit_measure),
                                                  flg_validation     => pk_orders_constant.g_component_error,
                                                  err_msg            => pk_message.get_message(i_lang, 'POSITIONING_T024'),
                                                  flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                  flg_multi_status   => NULL,
                                                  idx                => i_idx)
                          INTO tbl_result(tbl_result.count)
                          FROM ds_cmpt_mkt_rel d
                         WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
                    END IF;
                END IF;
            ELSE
                --Selecting/Deselecting elements in the viewer
                --IMPORTANT: For this action, it is necessary to send the information of ALL visible components (values and statuses)
                --(MEM components do not need to be sent, unless its values should be updated)
                --This is how the UX layer will now if the multiple elements selected in the viewer have multiple values for each field,
                --adding the tags 'Multiple'.
            
                --Obtain memory information
                FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                LOOP
                    IF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                    THEN
                        l_order_recurr_plan := to_number(i_value(i) (1));
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_flg_edition
                    THEN
                        l_flg_edition := i_value(i) (1);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_order_type
                    THEN
                        l_has_cosign_info := pk_alert_constant.g_yes;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_has_catalogue
                    THEN
                        l_has_catalogue := coalesce(i_value(i) (1), pk_alert_constant.g_no);
                    END IF;
                END LOOP;
            
                IF l_order_recurr_plan IS NOT NULL
                THEN
                    --Determine the values for the recurrence fields
                    IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                                  i_prof                => i_prof,
                                                                                  i_order_plan          => l_order_recurr_plan,
                                                                                  o_order_recurr_desc   => l_order_recurr_desc,
                                                                                  o_order_recurr_option => l_order_recurr_option,
                                                                                  o_start_date          => l_start_date,
                                                                                  o_occurrences         => l_occurrences,
                                                                                  o_duration            => l_duration,
                                                                                  o_unit_meas_duration  => l_unit_meas_duration,
                                                                                  o_end_date            => l_end_date,
                                                                                  o_flg_end_by_editable => l_flg_end_by_editable,
                                                                                  o_error               => o_error)
                    THEN
                        g_error := 'error while calling get_order_recurr_instructions function';
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                --Verify if the user needs co_sign to perform the request
                --The verification is only performed for the first record, the remaining records use the context variable
                --If there is no need for co_sign, the block will remain hidden
                IF i_idx = 1
                THEN
                    g_error := 'ERROR CALLING PK_CO_SIGN_UX.CHECK_PROF_NEEDS_COSIGN_ORDER';
                    IF NOT pk_co_sign_ux.check_prof_needs_cosign_order(i_lang                 => i_lang,
                                                                       i_prof                 => i_prof,
                                                                       i_episode              => i_episode,
                                                                       i_task_type            => CASE i_root_name
                                                                                                     WHEN
                                                                                                      pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                      11
                                                                                                     WHEN
                                                                                                      pk_orders_constant.g_ds_procedure_request THEN
                                                                                                      43
                                                                                                     WHEN
                                                                                                      pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                                                      7
                                                                                                     WHEN
                                                                                                      pk_orders_constant.g_ds_other_exam_request THEN
                                                                                                      8
                                                                                                 END,
                                                                       o_flg_prof_need_cosign => l_co_sign_available,
                                                                       o_error                => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    pk_context_api.set_parameter(p_name => 'l_co_sign_available', p_value => l_co_sign_available);
                ELSE
                    l_co_sign_available := alert_context('l_co_sign_available');
                END IF;
            
                FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                LOOP
                    l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
                
                    --Set of fields that are always active, regardless of configurations
                    IF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_clinical_indication_ft,
                                             pk_orders_constant.g_ds_priority,
                                             pk_orders_constant.g_ds_reason_not_ordering,
                                             pk_orders_constant.g_ds_financial_entity,
                                             pk_orders_constant.g_ds_health_coverage_plan,
                                             pk_orders_constant.g_ds_exemption,
                                             pk_orders_constant.g_ds_fasting,
                                             pk_orders_constant.g_ds_patient_notes,
                                             pk_orders_constant.g_ds_location,
                                             pk_orders_constant.g_ds_additional_notes,
                                             pk_orders_constant.g_ds_collection_place)
                       OR (i_tbl_int_name(i) = pk_orders_constant.g_ds_place_service AND
                           i_root_name = pk_orders_constant.g_ds_lab_test_request)
                       OR (i_tbl_int_name(i) = pk_orders_constant.g_ds_notes_execution AND
                           i_root_name <> pk_orders_constant.g_ds_lab_test_request)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE i_tbl_int_name(i)
                                                                                                     WHEN
                                                                                                      pk_orders_constant.g_ds_reason_not_ordering THEN
                                                                                                      CASE
                                                                                                       l_flg_show_reason_not_order
                                                                                                          WHEN
                                                                                                           pk_alert_constant.g_yes THEN
                                                                                                           pk_orders_constant.g_component_active
                                                                                                          ELSE
                                                                                                           pk_orders_constant.g_component_hidden
                                                                                                      END
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_clinical_indication_mw)
                    THEN
                        IF i_root_name = pk_orders_constant.g_ds_imaging_exam_request
                        THEN
                            l_clinical_indication_mandatory := pk_sysconfig.get_config('IMG_CLINICAL_INDICATION_MANDATORY',
                                                                                       i_prof);
                        ELSIF i_root_name = pk_orders_constant.g_ds_other_exam_request
                        THEN
                            l_clinical_indication_mandatory := pk_sysconfig.get_config('EXM_CLINICAL_INDICATION_MANDATORY',
                                                                                       i_prof);
                        END IF;
                    
                        FOR j IN i_value(i).first .. i_value(i).last
                        LOOP
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => i_value(i) (j),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (j),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      l_clinical_indication_mandatory
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_yes THEN
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_active
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END LOOP;
                    ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_to_execute_list, pk_orders_constant.g_ds_prn)
                          OR (i_tbl_int_name(i) IN (pk_orders_constant.g_ds_order_type,
                                                    pk_orders_constant.g_ds_ordered_by,
                                                    pk_orders_constant.g_ds_ordered_at) AND
                              l_co_sign_available = pk_alert_constant.g_yes)
                          OR (i_tbl_int_name(i) = pk_orders_constant.g_ds_place_service AND
                              i_root_name = pk_orders_constant.g_ds_procedure_request)
                    THEN
                        --These are fields that are always mandatory regardless of configurations
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_execution_ordered_at
                    THEN
                        IF (l_flg_edition = pk_alert_constant.g_no AND l_co_sign_available = pk_alert_constant.g_no)
                           OR (l_flg_edition = pk_alert_constant.g_yes AND l_has_cosign_info = pk_alert_constant.g_no)
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => i_value(i) (1),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_clinical_purpose
                    THEN
                        IF i_root_name = pk_orders_constant.g_ds_lab_test_request
                        THEN
                            l_clinical_purpose_mandatory := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_A',
                                                                                    i_prof);
                        ELSIF i_root_name = 'DS_BLOOD_PRODUCTS'
                        THEN
                            l_clinical_purpose_mandatory := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_BP',
                                                                                    i_prof);
                        ELSIF i_root_name = pk_orders_constant.g_ds_procedure_request
                        THEN
                            l_clinical_purpose_mandatory := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_P',
                                                                                    i_prof);
                        ELSIF i_root_name = pk_orders_constant.g_ds_imaging_exam_request
                        THEN
                            l_clinical_purpose_mandatory := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_I',
                                                                                    i_prof);
                        ELSIF i_root_name = pk_orders_constant.g_ds_other_exam_request
                        THEN
                            l_clinical_purpose_mandatory := pk_sysconfig.get_config('CLINICAL_PURPOSE_MANDATORY_E',
                                                                                    i_prof);
                        END IF;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                  l_clinical_purpose_mandatory
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_clinical_purpose_ft
                    THEN
                        FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_clinical_purpose
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => i_value(i) (1),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => i_value_desc(i) (1),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                          i_value(j) (1)
                                                                                                             WHEN '0' THEN
                                                                                                              pk_orders_constant.g_component_mandatory
                                                                                                             ELSE
                                                                                                              pk_orders_constant.g_component_inactive
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                                EXIT;
                            END IF;
                        END LOOP;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_laterality
                    THEN
                        IF i_root_name = pk_orders_constant.g_ds_procedure_request
                        THEN
                            l_laterality_mandatory := pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY',
                                                                              i_prof);
                        ELSIF i_root_name = pk_orders_constant.g_ds_imaging_exam_request
                        THEN
                            l_laterality_mandatory := pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY',
                                                                              i_prof);
                        ELSIF i_root_name = pk_orders_constant.g_ds_other_exam_request
                        THEN
                            l_laterality_mandatory := pk_sysconfig.get_config('EXAMS_ORDER_LATERALITY_MANDATORY',
                                                                              i_prof);
                        END IF;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE i_root_name
                                                                                                     WHEN
                                                                                                      pk_orders_constant.g_ds_lab_test_request THEN
                                                                                                      pk_orders_constant.g_component_hidden
                                                                                                     ELSE
                                                                                                      CASE l_flg_edition
                                                                                                          WHEN
                                                                                                           pk_alert_constant.g_no THEN
                                                                                                           pk_orders_utils.get_laterality_event_type(i_lang                 => i_lang,
                                                                                                                                                     i_prof                 => i_prof,
                                                                                                                                                     i_root_name            => i_root_name,
                                                                                                                                                     i_laterality_mandatory => l_laterality_mandatory,
                                                                                                                                                     i_idx                  => i_idx,
                                                                                                                                                     i_value_laterality     => i_value(i) (1),
                                                                                                                                                     i_tbl_data             => i_tbl_data)
                                                                                                          ELSE
                                                                                                           CASE
                                                                                                            l_laterality_mandatory
                                                                                                               WHEN
                                                                                                                pk_alert_constant.g_yes THEN
                                                                                                                pk_orders_constant.g_component_mandatory
                                                                                                               ELSE
                                                                                                                pk_orders_constant.g_component_active
                                                                                                           END
                                                                                                      END
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_prn_specify
                    THEN
                        FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_prn
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => i_value(i) (1),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => i_value_desc(i) (1),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                          i_value(j) (1)
                                                                                                             WHEN
                                                                                                              pk_alert_constant.g_yes THEN
                                                                                                              pk_orders_constant.g_component_active
                                                                                                             ELSE
                                                                                                              pk_orders_constant.g_component_inactive
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                                EXIT;
                            END IF;
                        END LOOP;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_frequency
                    THEN
                        FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_prn
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => i_value(i) (1),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => i_value_desc(i) (1),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                          i_value(j) (1)
                                                                                                             WHEN
                                                                                                              pk_alert_constant.g_yes THEN
                                                                                                              pk_orders_constant.g_component_read_only
                                                                                                             ELSE
                                                                                                              pk_orders_constant.g_component_mandatory
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                                EXIT;
                            END IF;
                        END LOOP;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                    THEN
                        FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_prn
                            THEN
                                l_flg_prn := i_value(j) (1);
                            ELSIF i_tbl_int_name(j) = pk_orders_constant.g_ds_flg_time
                            THEN
                                l_flg_time := i_value(j) (1);
                            END IF;
                        END LOOP;
                    
                        g_error := 'ERROR GETTING DT_EPIS_BEGIN';
                        SELECT e.dt_begin_tstz
                          INTO l_dt_epis_begin
                          FROM episode e
                         WHERE e.id_episode = i_episode;
                    
                        g_error                   := 'ERROR VALIDATING START DATE';
                        l_epis_begin_verification := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                                     i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                                 i_timestamp => l_dt_epis_begin,
                                                                                                                                 i_format    => 'MI'),
                                                                                     i_date2 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                                 i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                              i_prof,
                                                                                                                                                                              i_value(i) (1),
                                                                                                                                                                              NULL),
                                                                                                                                 i_format    => 'MI'));
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => CASE l_epis_begin_verification
                                                                                                     WHEN 'G' THEN
                                                                                                      pk_orders_constant.g_component_error
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_valid
                                                                                                 END,
                                                                           err_msg            => CASE l_epis_begin_verification
                                                                                                     WHEN 'G' THEN
                                                                                                      pk_message.get_message(i_lang,
                                                                                                                             'COMMON_M166')
                                                                                                 END,
                                                                           flg_event_type     => CASE i_tbl_int_name(i)
                                                                                                     WHEN pk_orders_constant.g_ds_date_dummy THEN
                                                                                                      pk_orders_constant.g_component_active
                                                                                                     ELSE
                                                                                                      CASE l_flg_prn
                                                                                                          WHEN pk_alert_constant.g_yes THEN
                                                                                                           pk_orders_constant.g_component_read_only
                                                                                                          ELSE
                                                                                                           CASE
                                                                                                               WHEN l_flg_time = pk_alert_constant.g_flg_time_b THEN
                                                                                                                pk_orders_constant.g_component_active
                                                                                                               WHEN l_flg_time = pk_alert_constant.g_flg_time_n THEN
                                                                                                                pk_orders_constant.g_component_inactive
                                                                                                               ELSE
                                                                                                                pk_orders_constant.g_component_mandatory
                                                                                                           END
                                                                                                      END
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_other_frequency
                    THEN
                        FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_frequency
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => i_value(i) (1),
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => i_value_desc(i) (1),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                          i_value(j) (1)
                                                                                                             WHEN -1 THEN
                                                                                                              pk_orders_constant.g_component_mandatory
                                                                                                             ELSE
                                                                                                              pk_orders_constant.g_component_inactive
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                                EXIT;
                            END IF;
                        END LOOP;
                    ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_executions,
                                                pk_orders_constant.g_ds_duration,
                                                pk_orders_constant.g_ds_end_date)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => CASE
                                                                                                     WHEN i_tbl_int_name(i) = pk_orders_constant.g_ds_duration THEN
                                                                                                      to_number(i_value_mea(i) (1))
                                                                                                     ELSE
                                                                                                      NULL
                                                                                                 END,
                                                                           desc_unit_measure  => CASE
                                                                                                     WHEN i_tbl_int_name(i) = pk_orders_constant.g_ds_duration THEN
                                                                                                      pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                                                                                   i_prof,
                                                                                                                                                   to_number(i_value_mea(i) (1)))
                                                                                                     ELSE
                                                                                                      NULL
                                                                                                 END,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE l_flg_end_by_editable
                                                                                                     WHEN pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_active
                                                                                                     ELSE
                                                                                                      CASE
                                                                                                          WHEN i_value(i) (1) IS NULL THEN
                                                                                                           pk_orders_constant.g_component_inactive
                                                                                                          ELSE
                                                                                                           pk_orders_constant.g_component_read_only
                                                                                                      END
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_lab_test_result,
                                                pk_orders_constant.g_ds_weight_kg,
                                                pk_orders_constant.g_ds_health_plan_number)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                     WHEN i_value(i) (1) IS NULL THEN
                                                                                                      pk_orders_constant.g_component_inactive
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_read_only
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_scheduling_notes
                    THEN
                        FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_flg_time
                            THEN
                                l_flg_time := i_value(j) (1);
                                EXIT;
                            END IF;
                        END LOOP;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE l_flg_time
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_flg_time_e THEN
                                                                                                      pk_orders_constant.g_component_inactive
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_notes_technician
                    THEN
                        IF i_root_name = pk_orders_constant.g_ds_imaging_exam_request
                        THEN
                            l_notes_tech_mandatory := pk_sysconfig.get_config('IMG_NOTES_TECH_MANDATORY', i_prof);
                        ELSIF i_root_name = pk_orders_constant.g_ds_other_exam_request
                        THEN
                            l_notes_tech_mandatory := pk_sysconfig.get_config('EXM_NOTES_TECH_MANDATORY', i_prof);
                        END IF;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                  l_notes_tech_mandatory
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_supply_order_mw,
                                                pk_orders_constant.g_ds_id_supply,
                                                pk_orders_constant.g_ds_supply_location,
                                                pk_orders_constant.g_ds_supply_dt_return,
                                                pk_orders_constant.g_ds_supply_quantity,
                                                pk_orders_constant.g_ds_supply_set)
                    THEN
                        FOR j IN i_value(i).first .. i_value(i).last
                        LOOP
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => CASE
                                                                                                      i_tbl_int_name(i)
                                                                                                         WHEN
                                                                                                          pk_orders_constant.g_ds_supply_order_mw THEN
                                                                                                          to_char(i_value(i) (j))
                                                                                                         ELSE
                                                                                                          to_char(coalesce(i_value(i) (j),
                                                                                                                           '-1'))
                                                                                                     END,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => i_value_desc(i) (j),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      i_tbl_int_name(i)
                                                                                                         WHEN
                                                                                                          pk_orders_constant.g_ds_supply_order_mw THEN
                                                                                                          pk_orders_constant.g_component_unique
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_active
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END LOOP;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_specimen
                    THEN
                        IF l_flg_edition = pk_alert_constant.g_no
                        THEN
                            --If the record is a Group, field 'Specimen' and 'Body location' must be inactive
                            --If there are more than one selected record, this field should be Read-only
                            IF i_tbl_data(i_idx) (3) = 'G'
                            THEN
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   value_clob         => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_inactive,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            ELSE
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => l_id_ds_component,
                                                                                   internal_name      => i_tbl_int_name(i),
                                                                                   VALUE              => i_value(i) (1),
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   value_clob         => NULL,
                                                                                   desc_value         => i_value_desc(i) (1),
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => CASE
                                                                                                             WHEN i_tbl_data.count = 1 THEN
                                                                                                              pk_orders_constant.g_component_mandatory
                                                                                                             ELSE
                                                                                                              pk_orders_constant.g_component_read_only
                                                                                                         END,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => i_idx);
                            END IF;
                        ELSE
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => i_value(i) (1),
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               value_clob         => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN i_tbl_id_pk.count = 1 THEN
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_read_only
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_body_location
                    THEN
                        --If the record is a Group, field 'Body location' must be inactive
                        IF l_flg_edition = pk_alert_constant.g_no
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => i_value(i) (1),
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               value_clob         => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                      i_tbl_data(i_idx) (3)
                                                                                                         WHEN 'G' THEN
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_active
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSE
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => i_value(i) (1),
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               value_clob         => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_notes_execution
                          AND i_root_name = pk_orders_constant.g_ds_lab_test_request
                    THEN
                        l_notes_execution_mandatory := pk_sysconfig.get_config('LAB_TESTS_NOTES_TECH_MANDATORY', i_prof);
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => i_value_desc(i) (1),
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => CASE
                                                                                                  l_notes_execution_mandatory
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_yes THEN
                                                                                                      pk_orders_constant.g_component_mandatory
                                                                                                     ELSE
                                                                                                      pk_orders_constant.g_component_active
                                                                                                 END,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_catalogue
                    THEN
                        IF l_has_catalogue = pk_alert_constant.g_yes
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => i_value(i) (1),
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               value_clob         => NULL,
                                                                               desc_value         => i_value_desc(i) (1),
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSE
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => l_id_ds_component,
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               value_clob         => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_inactive,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                        --MEMORY FIELDS
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_default_laterality
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => CASE l_flg_edition
                                                                                                     WHEN
                                                                                                      pk_alert_constant.g_no THEN
                                                                                                      i_tbl_data(i_idx) (3)
                                                                                                     ELSE
                                                                                                      i_value(i) (1)
                                                                                                 END,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_dummy_number
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => l_order_recurr_plan,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_tbl_records
                    THEN
                        FOR j IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(j) = pk_orders_constant.g_ds_flg_edition
                            THEN
                                l_flg_edition := i_value(j) (1);
                                EXIT;
                            END IF;
                        END LOOP;
                    
                        l_tbl_varchar_aux := table_varchar();
                    
                        IF l_flg_edition = pk_alert_constant.g_no
                        THEN
                            FOR j IN i_tbl_data.first .. i_tbl_data.last
                            LOOP
                                l_tbl_varchar_aux.extend;
                                l_tbl_varchar_aux(l_tbl_varchar_aux.count) := i_tbl_data(j) (1);
                            END LOOP;
                        ELSE
                            FOR j IN i_tbl_id_pk.first .. i_tbl_id_pk.last
                            LOOP
                                l_tbl_varchar_aux.extend;
                                l_tbl_varchar_aux(l_tbl_varchar_aux.count) := i_tbl_id_pk(j);
                            END LOOP;
                        END IF;
                    
                        SELECT listagg(t.column_value, '|') /*+opt_estimate(table t rows=1)*/
                          INTO l_varchar_aux
                          FROM TABLE(l_tbl_varchar_aux) t;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => l_varchar_aux,
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    
                    ELSIF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_next_episode_id,
                                                pk_orders_constant.g_ds_no_later_than,
                                                pk_orders_constant.g_ds_date_dummy,
                                                pk_orders_constant.g_ds_flg_time)
                    THEN
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => i_value(i) (1),
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           value_clob         => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END IF;
                END LOOP;
            END IF;
        ELSE
            --EDITION            
            IF i_root_name = pk_orders_constant.g_ds_procedure_request
            THEN
                g_error := 'ERROR CALLING PK_PROCEDURES_CORE.GET_PROCEDURE_TO_EDIT';
                IF NOT pk_procedures_core.get_procedure_to_edit(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_episode        => i_episode,
                                                                i_patient        => i_patient,
                                                                i_action         => i_action,
                                                                i_root_name      => i_root_name,
                                                                i_curr_component => i_curr_component,
                                                                i_idx            => i_idx,
                                                                i_tbl_id_pk      => i_tbl_id_pk,
                                                                i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                i_tbl_int_name   => i_tbl_int_name,
                                                                i_value          => i_value,
                                                                i_value_desc     => i_value_desc,
                                                                i_tbl_data       => i_tbl_data,
                                                                i_value_clob     => i_value_clob,
                                                                i_tbl_result     => tbl_result,
                                                                o_error          => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        --For each action (New form, Component submit, Selecting/Deselecting in the viewer, Edition)
        --it is necessary to tell the UX layer if the form is valid. This will allow the UX to activete/inactivate the OK button,
        --and also to activate/inactivate the pencil from the viewer for each record.
        --For this function to perform the verification, the hidden component DS_OK_CONTROL_BUTTON must be configured in the form.
        g_error := 'ERROR CALLING PK_ORDERS_UTILS.GET_OK_BUTTON_CONTROL';
        IF NOT pk_orders_utils.get_ok_button_control(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_episode        => i_episode,
                                                     i_patient        => i_patient,
                                                     i_action         => i_action,
                                                     i_root_name      => i_root_name,
                                                     i_curr_component => i_curr_component,
                                                     i_idx            => i_idx,
                                                     i_tbl_id_pk      => i_tbl_id_pk,
                                                     i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                     i_tbl_int_name   => i_tbl_int_name,
                                                     i_value          => i_value,
                                                     i_value_desc     => i_value_desc,
                                                     i_tbl_data       => i_tbl_data,
                                                     i_value_clob     => i_value_clob,
                                                     i_tbl_result     => tbl_result,
                                                     o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_generic_form_values;

    FUNCTION get_to_execute_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_TO_EXECUTE_FORM_VALUES';
    
        --Return variable
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        --Control variables to cycle through the input parameters
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        --Form variables
        l_flg_time             VARCHAR2(1 CHAR);
        l_time_desc            VARCHAR2(1000 CHAR);
        l_id_epis_to_execute   episode.id_episode%TYPE;
        l_epis_to_execute_desc VARCHAR2(1000 CHAR);
        l_start_date           VARCHAR(50 CHAR);
        l_no_later_than        VARCHAR(50 CHAR);
    
        --Recurrence variables
        l_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
    
        --Area of caller form (Procedures, Lab tests, etc.)
        l_area order_recurr_plan.id_order_recurr_area%TYPE;
    
        /*###########################################*/
        --i_tbl_data will receive the data from the caller form on the following order:
        --i_tbl_data(i_idx)(1) => DS_FLG_TIME
        --i_tbl_data(i_idx)(2) => DS_DATE_DUMMY
        --i_tbl_data(i_idx)(3) => DS_NEXT_EPISODE_ID
        --i_tbl_data(i_idx)(4) => DS_NO_LATER_THAN
        --i_tbl_data(i_idx)(5) => DS_DUMMY_NUMBER
    
    BEGIN
        --An nvl is performed for the sysdate in order to assure the same current date for every i_idx iteration
        g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        IF i_action IS NULL
           OR i_action = -1 --NEW FORM (default values)
        THEN
            --Id recurrence
            g_error             := 'GETTING ID_ORDER_RECURR_PLAN';
            l_order_recurr_plan := to_number(i_tbl_data(i_idx) (5));
        
            g_error := 'GETTING ORDER RECURR PLAN AREA';
            SELECT orp.id_order_recurr_area
              INTO l_area
              FROM order_recurr_plan orp
             WHERE orp.id_order_recurr_plan = l_order_recurr_plan;
        
            --To execute field
            g_error    := 'GETTING FLG_TIME';
            l_flg_time := i_tbl_data(i_idx) (1);
        
            --Episode field
            g_error              := 'GETTING ID EPISODE TO EXECUTE';
            l_id_epis_to_execute := to_number(i_tbl_data(i_idx) (3));
        
            IF l_id_epis_to_execute IS NOT NULL
            THEN
                g_error := 'GETTING EPISODE TO EXECUTE DESC';
                SELECT /*+opt_estimate (table t rows=1)*/
                 t.event_type_name_title || ': ' || t.event_type_clinical_service || '; ' ||
                 (SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
                    FROM sch_event se
                   WHERE se.id_sch_event = t.sch_event) || '; ' || t.professional
                  INTO l_epis_to_execute_desc
                  FROM TABLE(pk_events.get_patient_future_events_pl(i_lang, i_prof, i_patient)) t
                 WHERE t.id_episode = l_id_epis_to_execute;
            END IF;
        
            g_error     := 'GETTING TIME_DESC';
            l_time_desc := pk_sysdomain.get_domain(i_code_dom => CASE l_area
                                                                     WHEN pk_order_recurrence_core.g_area_lab_test THEN
                                                                      'ANALYSIS_REQ_DET.FLG_TIME_HARVEST'
                                                                     WHEN pk_order_recurrence_core.g_area_image_exam THEN
                                                                      'EXAM_REQ.FLG_TIME'
                                                                     WHEN pk_order_recurrence_core.g_area_other_exam THEN
                                                                      'EXAM_REQ.FLG_TIME'
                                                                     WHEN pk_order_recurrence_core.g_area_procedure THEN
                                                                      'INTERV_PRESCRIPTION.FLG_TIME'
                                                                 END,
                                                   i_val      => l_flg_time,
                                                   i_lang     => i_lang);
        
            --Insert the default values in the return variable (tbl_result)
            g_error := 'SELECT INTO TBL_RESULT';
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_execute THEN
                                                                  l_flg_time
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_episode THEN
                                                                  to_char(l_id_epis_to_execute)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_start_date THEN
                                                                  i_tbl_data(i_idx) (2)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_no_later THEN
                                                                  i_tbl_data(i_idx) (4)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_dummy_number THEN
                                                                  i_tbl_data(i_idx) (5)
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_execute THEN
                                                                  l_time_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_episode THEN
                                                                  l_epis_to_execute_desc
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => coalesce(def.flg_event_type,
                                                                      CASE t.internal_name_child
                                                                          WHEN pk_orders_constant.g_ds_episode THEN
                                                                           decode(l_flg_time,
                                                                                  pk_alert_constant.g_flg_time_n,
                                                                                  pk_orders_constant.g_component_mandatory,
                                                                                  pk_orders_constant.g_component_inactive)
                                                                          WHEN pk_orders_constant.g_ds_start_date THEN
                                                                           decode(l_flg_time,
                                                                                  pk_alert_constant.g_flg_time_n,
                                                                                  pk_orders_constant.g_component_inactive,
                                                                                  pk_alert_constant.g_flg_time_b,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  pk_orders_constant.g_component_mandatory)
                                                                          WHEN pk_orders_constant.g_ds_no_later THEN
                                                                           decode(l_flg_time,
                                                                                  pk_alert_constant.g_flg_time_b,
                                                                                  pk_orders_constant.g_component_active,
                                                                                  pk_orders_constant.g_component_inactive)
                                                                          ELSE
                                                                           pk_orders_constant.g_component_active
                                                                      END),
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.flg_component_type = 'L'
             ORDER BY t.rn;
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            --Action of submiting a value on any given element of the form
            --IMPORTANT: In order for this action to be executed, a submit action must be configured in ds_event for the given field,
            --otherwise, the i_curr_component is null.
            IF i_curr_component IS NOT NULL
            THEN
                --Check which element has been changed
                SELECT d.internal_name_child
                  INTO l_curr_comp_int_name
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
            
                IF l_curr_comp_int_name = pk_orders_constant.g_ds_execute
                THEN
                    l_flg_time := pk_orders_utils.get_value(l_curr_comp_int_name, i_tbl_mkt_rel, i_value);
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_episode
                        THEN
                        
                            l_id_epis_to_execute   := to_number(pk_orders_utils.get_value(i_tbl_int_name(i),
                                                                                          i_tbl_mkt_rel,
                                                                                          i_value));
                            l_epis_to_execute_desc := pk_orders_utils.get_value(i_tbl_int_name(i),
                                                                                i_tbl_mkt_rel,
                                                                                i_value_desc);
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i)),
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => l_id_epis_to_execute,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_epis_to_execute_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_flg_time
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_flg_time_n THEN
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                        THEN
                            l_start_date := pk_orders_utils.get_value(i_tbl_int_name(i), i_tbl_mkt_rel, i_value);
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i)),
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => CASE l_flg_time
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_flg_time_b THEN
                                                                                                          NULL
                                                                                                         ELSE
                                                                                                          coalesce(l_start_date,
                                                                                                                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                                               i_date => g_sysdate_tstz,
                                                                                                                                               i_prof => i_prof))
                                                                                                     END,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_flg_time
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_flg_time_n THEN
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_flg_time_b THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_no_later
                        THEN
                            l_no_later_than := pk_orders_utils.get_value(i_tbl_int_name(i), i_tbl_mkt_rel, i_value);
                        
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i)),
                                                                               internal_name      => i_tbl_int_name(i),
                                                                               VALUE              => l_no_later_than,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_valid,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE l_flg_time
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_flg_time_b THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        END IF;
                    END LOOP;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_start_date
                THEN
                    l_start_date := pk_orders_utils.get_value(l_curr_comp_int_name, i_tbl_mkt_rel, i_value);
                
                    IF l_start_date IS NOT NULL
                    THEN
                        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                        LOOP
                            IF i_tbl_int_name(i) = pk_orders_constant.g_ds_execute
                            THEN
                                l_flg_time := pk_orders_utils.get_value(i_tbl_int_name(i), i_tbl_mkt_rel, i_value);
                            ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_no_later
                            THEN
                                l_no_later_than := pk_orders_utils.get_value(i_tbl_int_name(i), i_tbl_mkt_rel, i_value);
                            END IF;
                        END LOOP;
                    
                        IF l_start_date IS NOT NULL
                           AND
                           pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                           i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                       i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                    i_prof,
                                                                                                                                                    l_start_date,
                                                                                                                                                    NULL),
                                                                                                       i_format    => 'MI'),
                                                           i_date2 => pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                               i_inst      => i_prof.institution,
                                                                                                               i_timestamp => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                                                               i_timestamp => g_sysdate_tstz,
                                                                                                                                                               i_format    => 'MI'))) = 'L'
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_curr_component,
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_curr_component),
                                                                               internal_name      => l_curr_comp_int_name,
                                                                               VALUE              => l_start_date,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_error,
                                                                               err_msg            => pk_message.get_message(i_lang,
                                                                                                                            'COMMON_T066'),
                                                                               flg_event_type     => CASE l_flg_time
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_flg_time_n THEN
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                         WHEN
                                                                                                          pk_alert_constant.g_flg_time_b THEN
                                                                                                          pk_orders_constant.g_component_active
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        ELSIF l_no_later_than IS NOT NULL
                              AND l_start_date IS NOT NULL
                              AND
                              pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                          i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                       i_prof,
                                                                                                                                                       l_no_later_than,
                                                                                                                                                       NULL),
                                                                                                          i_format    => 'MI'),
                                                              i_date2 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                          i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                       i_prof,
                                                                                                                                                       l_start_date,
                                                                                                                                                       NULL),
                                                                                                          i_format    => 'MI')) = 'L'
                        THEN
                            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF i_tbl_int_name(i) = pk_orders_constant.g_ds_no_later
                                THEN
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                       id_ds_component    => pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i)),
                                                                                       internal_name      => i_tbl_int_name(i),
                                                                                       VALUE              => l_no_later_than,
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => NULL,
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_orders_constant.g_component_error,
                                                                                       err_msg            => pk_message.get_message(i_lang,
                                                                                                                                    'COMMON_T067'),
                                                                                       flg_event_type     => CASE
                                                                                                              l_flg_time
                                                                                                                 WHEN
                                                                                                                  pk_alert_constant.g_flg_time_b THEN
                                                                                                                  pk_orders_constant.g_component_active
                                                                                                                 ELSE
                                                                                                                  pk_orders_constant.g_component_inactive
                                                                                                             END,
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => i_idx);
                                    EXIT;
                                END IF;
                            END LOOP;
                        END IF;
                    END IF;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_no_later
                THEN
                    l_no_later_than := pk_orders_utils.get_value(l_curr_comp_int_name, i_tbl_mkt_rel, i_value);
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_start_date
                        THEN
                            l_start_date := pk_orders_utils.get_value(i_tbl_int_name(i), i_tbl_mkt_rel, i_value);
                            EXIT;
                        END IF;
                    END LOOP;
                
                    IF l_no_later_than IS NOT NULL
                    THEN
                        IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                           i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                       i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                    i_prof,
                                                                                                                                                    l_no_later_than,
                                                                                                                                                    NULL),
                                                                                                       i_format    => 'MI'),
                                                           i_date2 => pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                               i_inst      => i_prof.institution,
                                                                                                               i_timestamp => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                                                               i_timestamp => g_sysdate_tstz,
                                                                                                                                                               i_format    => 'MI'))) = 'L'
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_curr_component,
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_curr_component),
                                                                               internal_name      => l_curr_comp_int_name,
                                                                               VALUE              => l_no_later_than,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_error,
                                                                               err_msg            => pk_message.get_message(i_lang,
                                                                                                                            'COMMON_T066'),
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        ELSIF l_start_date IS NOT NULL
                              AND
                              pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                          i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                       i_prof,
                                                                                                                                                       l_no_later_than,
                                                                                                                                                       NULL),
                                                                                                          i_format    => 'MI'),
                                                              i_date2 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                          i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                       i_prof,
                                                                                                                                                       l_start_date,
                                                                                                                                                       NULL),
                                                                                                          i_format    => 'MI')) = 'L'
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_curr_component,
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_curr_component),
                                                                               internal_name      => l_curr_comp_int_name,
                                                                               VALUE              => l_no_later_than,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_orders_constant.g_component_error,
                                                                               err_msg            => pk_message.get_message(i_lang,
                                                                                                                            'COMMON_T067'),
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => i_idx);
                        
                        END IF;
                    END IF;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_episode
                THEN
                    --Episode field
                    g_error              := 'GETTING ID EPISODE TO EXECUTE';
                    l_id_epis_to_execute := to_number(pk_orders_utils.get_value(l_curr_comp_int_name,
                                                                                i_tbl_mkt_rel,
                                                                                i_value));
                
                    IF l_id_epis_to_execute IS NOT NULL
                    THEN
                        g_error := 'GETTING EPISODE TO EXECUTE DESC';
                        SELECT /*+opt_estimate (table t rows=1)*/
                         t.event_type_name_title || ': ' || t.event_type_clinical_service || '; ' ||
                         (SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
                            FROM sch_event se
                           WHERE se.id_sch_event = t.sch_event) || '; ' || t.professional
                          INTO l_epis_to_execute_desc
                          FROM TABLE(pk_events.get_patient_future_events_pl(i_lang, i_prof, i_patient)) t
                         WHERE t.id_episode = l_id_epis_to_execute;
                    
                        tbl_result.extend();
                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_curr_component,
                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_curr_component),
                                                                           internal_name      => l_curr_comp_int_name,
                                                                           VALUE              => to_char(l_id_epis_to_execute),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => l_epis_to_execute_desc,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_to_execute_form_values;

    FUNCTION get_p1_ok_button_state
    (
        i_lang                         IN NUMBER,
        i_prof                         IN profissional,
        i_episode                      IN NUMBER,
        i_patient                      IN NUMBER,
        i_action                       IN NUMBER,
        i_root_name                    IN VARCHAR2,
        i_curr_component               IN NUMBER,
        i_tbl_id_pk                    IN table_number,
        i_tbl_mkt_rel                  IN table_number,
        i_value                        IN table_table_varchar,
        i_complementary_info_mandatory IN VARCHAR2 DEFAULT NULL,
        o_error                        OUT t_error_out
    ) RETURN t_rec_ds_get_value IS
        l_result t_rec_ds_get_value;
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        l_flg_home     VARCHAR2(10);
        l_flg_priority VARCHAR2(10);
    
        l_reason_mandatory    sys_config.value%TYPE;
        l_diagnosis_mandatory sys_config.value%TYPE;
        l_consent_mandatory   sys_config.value%TYPE;
    
        l_reason_has_text             BOOLEAN := FALSE;
        l_consent_has_text            BOOLEAN := FALSE;
        l_diagnosis_has_text          BOOLEAN := FALSE;
        l_complementary_info_has_text BOOLEAN := FALSE;
    
        l_ok_available BOOLEAN := TRUE;
        l_flg_state    VARCHAR2(1) := 'A';
    BEGIN
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_p1_home
            THEN
                l_flg_home := i_value(i) (1);
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_priority
            THEN
                l_flg_priority := i_value(i) (1);
            END IF;
        END LOOP;
    
        --Check if the Reason field should be mandatory
        IF NOT pk_ref_service.check_referral_reason(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_type             => CASE i_root_name
                                                                              WHEN pk_orders_utils.g_p1_appointment THEN
                                                                               'C'
                                                                              WHEN pk_orders_utils.g_p1_lab_test THEN
                                                                               'A'
                                                                              WHEN pk_orders_utils.g_p1_intervention THEN
                                                                               'P'
                                                                              WHEN pk_orders_utils.g_p1_imaging_exam THEN
                                                                               'I'
                                                                              WHEN pk_orders_utils.g_p1_other_exam THEN
                                                                               'E'
                                                                              WHEN pk_orders_utils.g_p1_rehab THEN
                                                                               'F'
                                                                          END,
                                                    i_home             => table_varchar(l_flg_home),
                                                    i_priority         => table_varchar(l_flg_priority),
                                                    o_reason_mandatory => l_reason_mandatory,
                                                    o_error            => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --Check if field consent is mandatory
        l_consent_mandatory := pk_sysconfig.get_config('P1_CONSENT', i_prof);
    
        --Check if field diagnosis is mandatory
        l_diagnosis_mandatory := pk_sysconfig.get_config(pk_ref_constant.g_ref_diag_mandatory, i_prof);
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_diagnosis
            THEN
                IF i_value(i) (1) IS NOT NULL
                THEN
                    l_diagnosis_has_text := TRUE;
                END IF;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_referral_reason
            THEN
                IF i_value(i) (1) IS NOT NULL
                THEN
                    l_reason_has_text := TRUE;
                END IF;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_referral_consent
            THEN
                IF i_value(i) (1) IS NOT NULL
                THEN
                    l_consent_has_text := TRUE;
                END IF;
            ELSIF l_ds_internal_name = pk_orders_constant.g_ds_complementary_information
            THEN
                IF i_value(i) (1) IS NOT NULL
                THEN
                    l_complementary_info_has_text := TRUE;
                END IF;
            END IF;
        END LOOP;
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            l_ds_internal_name := get_ds_internal_name(i_tbl_mkt_rel(i));
            l_id_ds_component  := get_id_ds_component(i_tbl_mkt_rel(i));
        
            IF l_ds_internal_name = pk_orders_constant.g_ds_ok_button_control
            THEN
                IF (l_diagnosis_has_text = FALSE AND l_diagnosis_mandatory = pk_alert_constant.g_yes)
                   OR (l_reason_has_text = FALSE AND l_reason_mandatory = pk_alert_constant.g_yes)
                   OR (l_consent_has_text = FALSE AND l_consent_mandatory = pk_alert_constant.g_yes)
                   OR
                   (l_complementary_info_has_text = FALSE AND i_complementary_info_mandatory = pk_alert_constant.g_yes)
                THEN
                    l_flg_state := 'M';
                END IF;
            
                l_result := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                               id_ds_component    => l_id_ds_component,
                                               internal_name      => l_ds_internal_name,
                                               VALUE              => NULL,
                                               value_clob         => NULL,
                                               min_value          => NULL,
                                               max_value          => NULL,
                                               desc_value         => NULL,
                                               desc_clob          => NULL,
                                               id_unit_measure    => NULL,
                                               desc_unit_measure  => NULL,
                                               flg_validation     => pk_alert_constant.g_yes,
                                               err_msg            => NULL,
                                               flg_event_type     => l_flg_state,
                                               flg_multi_status   => NULL,
                                               idx                => 1);
            END IF;
        END LOOP;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_P1_OK_BUTTON_STATE',
                                              o_error);
            RETURN l_result;
    END get_p1_ok_button_state;

    FUNCTION get_generic_ok_button_state
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_episode                    IN NUMBER,
        i_root_name                  IN VARCHAR2,
        i_idx                        IN NUMBER,
        i_id_ds_cmpt_mkt_rel_control IN NUMBER,
        i_tbl_rec_ds                 IN OUT t_tbl_ds_get_value,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_result t_rec_ds_get_value;
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_ds_internal_name   ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        l_complementary_info_has_text BOOLEAN := FALSE;
    
        l_ok_available BOOLEAN := TRUE;
    BEGIN
    
        FOR i IN i_tbl_rec_ds.first .. i_tbl_rec_ds.last
        LOOP
            IF i_tbl_rec_ds(i).id_ds_cmpt_mkt_rel <> i_id_ds_cmpt_mkt_rel_control
            THEN
                IF i_tbl_rec_ds(i).flg_event_type = 'M'
                    AND i_tbl_rec_ds(i).desc_value IS NULL
                    AND i_tbl_rec_ds(i).value IS NULL
                THEN
                    l_ok_available := FALSE;
                    EXIT;
                END IF;
            END IF;
        END LOOP;
    
        IF l_ok_available = TRUE
        THEN
            FOR i IN i_tbl_rec_ds.first .. i_tbl_rec_ds.last
            LOOP
                IF i_tbl_rec_ds(i).id_ds_cmpt_mkt_rel <> i_id_ds_cmpt_mkt_rel_control
                THEN
                    IF i_tbl_rec_ds(i).flg_validation IS NOT NULL
                        OR i_tbl_rec_ds(i).flg_validation <> 'A'
                    THEN
                        l_ok_available := FALSE;
                        EXIT;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        l_ds_internal_name := get_ds_internal_name(i_id_ds_cmpt_mkt_rel_control);
        l_id_ds_component  := get_id_ds_component(i_id_ds_cmpt_mkt_rel_control);
    
        i_tbl_rec_ds.extend();
        i_tbl_rec_ds(i_tbl_rec_ds.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_ds_cmpt_mkt_rel_control,
                                                               id_ds_component    => l_id_ds_component,
                                                               internal_name      => l_ds_internal_name,
                                                               VALUE              => NULL,
                                                               value_clob         => NULL,
                                                               min_value          => NULL,
                                                               max_value          => NULL,
                                                               desc_value         => NULL,
                                                               desc_clob          => NULL,
                                                               id_unit_measure    => NULL,
                                                               desc_unit_measure  => NULL,
                                                               flg_validation     => pk_alert_constant.g_yes,
                                                               err_msg            => NULL,
                                                               flg_event_type     => CASE l_ok_available
                                                                                         WHEN TRUE THEN
                                                                                          'A'
                                                                                         ELSE
                                                                                          'M'
                                                                                     END,
                                                               flg_multi_status   => NULL,
                                                               idx                => 1);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GENERIC_OK_BUTTON_STATE',
                                              o_error);
            RETURN FALSE;
    END get_generic_ok_button_state;

    FUNCTION get_piped_analysis
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_analysis_inst_soft IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_tbl_analysis_inst_soft table_number;
        l_ret                    VARCHAR2(1000);
    BEGIN
        l_tbl_analysis_inst_soft := pk_utils.str_split_n(i_list => i_analysis_inst_soft, i_delim => '|');
    
        SELECT listagg(id_analysis, '|')
          INTO l_ret
          FROM (SELECT DISTINCT ais.id_analysis
                  FROM analysis_instit_soft ais
                 WHERE ais.id_analysis_instit_soft IN
                       (SELECT * /*+opt_estimate(table t rows=1)*/
                          FROM TABLE(l_tbl_analysis_inst_soft) t));
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_piped_analysis;

    FUNCTION get_piped_rehab_interv
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_rehab_area_interv IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_tbl_rehab_interv table_number;
        l_ret              VARCHAR2(1000);
    BEGIN
        l_tbl_rehab_interv := pk_utils.str_split_n(i_list => i_rehab_area_interv, i_delim => '|');
    
        SELECT listagg(id_intervention, '|')
          INTO l_ret
          FROM (SELECT DISTINCT r.id_intervention
                  FROM rehab_area_interv r
                 WHERE r.id_rehab_area_interv IN (SELECT * /*+opt_estimate(table t rows=1)*/
                                                    FROM TABLE(l_tbl_rehab_interv) t));
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_piped_rehab_interv;

    FUNCTION get_patient_health_plan_entity
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_list                    pk_types.cursor_type;
        l_id_pat_health_plan      pat_health_plan.id_pat_health_plan%TYPE;
        l_id_health_plan_entity   health_plan.id_health_plan_entity%TYPE;
        l_desc_health_plan_entity pk_translation.t_desc_translation;
        l_id_health_plan          health_plan.id_health_plan%TYPE;
        l_desc_health_plan        pk_translation.t_desc_translation;
        l_num_health_plan         pat_health_plan.num_health_plan%TYPE;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
        l_count PLS_INTEGER := 0;
    
        l_id_market            market.id_market%TYPE;
        l_national_health_plan health_plan.id_content%TYPE := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID',
                                                                                      i_prof);
    BEGIN
    
        g_error     := 'GET INSTITUTION MARKET';
        l_id_market := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
        IF NOT pk_adt.get_pat_health_plans(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_patient      => i_patient,
                                           o_pat_health_plan => l_list,
                                           o_error           => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        DELETE tbl_temp;
    
        LOOP
            FETCH l_list
                INTO l_id_pat_health_plan,
                     l_id_health_plan,
                     l_desc_health_plan,
                     l_desc_health_plan_entity,
                     l_id_health_plan_entity,
                     l_num_health_plan;
            EXIT WHEN l_list%NOTFOUND;
        
            SELECT COUNT(1)
              INTO l_count
              FROM tbl_temp t
             WHERE t.num_2 = l_id_health_plan_entity;
        
            IF l_count = 0
            THEN
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
                VALUES
                    (l_id_pat_health_plan,
                     l_id_health_plan_entity,
                     l_desc_health_plan_entity,
                     l_id_health_plan,
                     l_desc_health_plan,
                     l_num_health_plan,
                     10);
            END IF;
        END LOOP;
    
        g_error := 'OPEN L_RET';
        IF l_id_market = pk_alert_constant.g_id_market_pt
        THEN
            SELECT *
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t_row_core_domain(internal_name => NULL,
                                             desc_domain   => desc_health_plan_entity,
                                             domain_value  => id_health_plan_entity,
                                             order_rank    => NULL,
                                             img_name      => NULL)
                      FROM (SELECT num_1 id_pat_health_plan,
                                   num_2 id_health_plan_entity,
                                   vc_1  desc_health_plan_entity,
                                   num_2 id_health_plan,
                                   vc_2  desc_health_plan,
                                   vc_3  num_health_plan
                              FROM tbl_temp t
                              JOIN pat_health_plan php
                                ON php.id_pat_health_plan = t.num_1
                              JOIN health_plan hp
                                ON hp.id_health_plan = php.id_health_plan
                             WHERE php.id_patient = i_patient
                               AND php.id_institution IN
                                   (SELECT *
                                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                               pk_ehr_access.g_inst_grp_flg_rel_adt)))
                               AND php.flg_status = pk_edis_proc.g_hplan_active
                               AND (hp.flg_type IN ('P', 'S', 'E', 'A', 'B') OR hp.id_content = l_national_health_plan)
                             ORDER BY num_3));
        ELSE
            SELECT *
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t_row_core_domain(internal_name => NULL,
                                             desc_domain   => desc_health_plan_entity,
                                             domain_value  => id_health_plan_entity,
                                             order_rank    => NULL,
                                             img_name      => NULL)
                      FROM (SELECT num_1 id_pat_health_plan,
                                   num_2 id_health_plan_entity,
                                   vc_1  desc_health_plan_entity,
                                   num_2 id_health_plan,
                                   vc_2  desc_health_plan,
                                   vc_3  num_health_plan
                              FROM tbl_temp
                             ORDER BY num_3));
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_HEALTH_PLAN_ENTITY',
                                              l_error);
            RETURN l_ret;
    END get_patient_health_plan_entity;

    FUNCTION get_patient_health_plan_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_list                    pk_types.cursor_type;
        l_id_pat_health_plan      pat_health_plan.id_pat_health_plan%TYPE;
        l_id_health_plan_entity   health_plan.id_health_plan_entity%TYPE;
        l_desc_health_plan_entity pk_translation.t_desc_translation;
        l_id_health_plan          health_plan.id_health_plan%TYPE;
        l_desc_health_plan        pk_translation.t_desc_translation;
        l_num_health_plan         pat_health_plan.num_health_plan%TYPE;
    
        l_id_market            market.id_market%TYPE;
        l_national_health_plan health_plan.id_content%TYPE := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID',
                                                                                      i_prof);
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        g_error     := 'GET INSTITUTION MARKET';
        l_id_market := pk_prof_utils.get_prof_market(i_prof => i_prof);
    
        IF NOT pk_adt.get_pat_health_plans(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_patient      => i_patient,
                                           o_pat_health_plan => l_list,
                                           o_error           => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        DELETE tbl_temp;
    
        LOOP
            FETCH l_list
                INTO l_id_pat_health_plan,
                     l_id_health_plan,
                     l_desc_health_plan,
                     l_desc_health_plan_entity,
                     l_id_health_plan_entity,
                     l_num_health_plan;
            EXIT WHEN l_list%NOTFOUND;
        
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
            VALUES
                (l_id_pat_health_plan,
                 l_id_health_plan_entity,
                 l_desc_health_plan_entity,
                 l_id_health_plan,
                 l_desc_health_plan,
                 l_num_health_plan,
                 10);
        END LOOP;
        g_error := 'OPEN L_RET';
        IF l_id_market = pk_alert_constant.g_id_market_pt
        THEN
            SELECT *
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t_row_core_domain(internal_name => NULL,
                                             desc_domain   => desc_health_plan,
                                             domain_value  => id_pat_health_plan,
                                             order_rank    => NULL,
                                             img_name      => NULL)
                      FROM (SELECT num_1 id_pat_health_plan,
                                   num_2 id_health_plan_entity,
                                   vc_1  desc_health_plan_entity,
                                   num_2 id_health_plan,
                                   vc_2  desc_health_plan,
                                   vc_3  num_health_plan
                              FROM tbl_temp t
                              JOIN pat_health_plan php
                                ON php.id_pat_health_plan = t.num_1
                              JOIN health_plan hp
                                ON hp.id_health_plan = php.id_health_plan
                             WHERE (num_2 = i_health_plan_entity OR i_health_plan_entity IS NULL)
                               AND php.id_patient = i_patient
                               AND php.id_institution IN
                                   (SELECT *
                                      FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                               pk_ehr_access.g_inst_grp_flg_rel_adt)))
                               AND php.flg_status = pk_edis_proc.g_hplan_active
                               AND (hp.flg_type IN ('P', 'S', 'E', 'A', 'B') OR hp.id_content = l_national_health_plan)
                             ORDER BY num_3));
        
        ELSE
            SELECT *
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t_row_core_domain(internal_name => NULL,
                                             desc_domain   => desc_health_plan,
                                             domain_value  => id_pat_health_plan,
                                             order_rank    => NULL,
                                             img_name      => NULL)
                      FROM (SELECT num_1 id_pat_health_plan,
                                   num_2 id_health_plan_entity,
                                   vc_1  desc_health_plan_entity,
                                   num_2 id_health_plan,
                                   vc_2  desc_health_plan,
                                   vc_3  num_health_plan
                              FROM tbl_temp
                             WHERE (num_2 = i_health_plan_entity OR i_health_plan_entity IS NULL)
                             ORDER BY num_3));
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_HEALTH_PLAN_LIST',
                                              l_error);
            RETURN l_ret;
    END get_patient_health_plan_list;

    FUNCTION get_patient_beneficiary_number
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE,
        i_health_plan        IN health_plan.id_health_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_list                    pk_types.cursor_type;
        l_id_pat_health_plan      pat_health_plan.id_pat_health_plan%TYPE;
        l_id_health_plan_entity   health_plan.id_health_plan_entity%TYPE;
        l_desc_health_plan_entity pk_translation.t_desc_translation;
        l_id_health_plan          health_plan.id_health_plan%TYPE;
        l_desc_health_plan        pk_translation.t_desc_translation;
        l_num_health_plan         pat_health_plan.num_health_plan%TYPE;
    
        l_ret   VARCHAR2(1000);
        l_error t_error_out;
    BEGIN
    
        IF NOT pk_adt.get_pat_health_plans(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_id_patient      => i_patient,
                                           o_pat_health_plan => l_list,
                                           o_error           => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        DELETE tbl_temp;
    
        LOOP
            FETCH l_list
                INTO l_id_pat_health_plan,
                     l_id_health_plan,
                     l_desc_health_plan,
                     l_desc_health_plan_entity,
                     l_id_health_plan_entity,
                     l_num_health_plan;
            EXIT WHEN l_list%NOTFOUND;
        
            INSERT INTO tbl_temp
                (num_1, num_2, vc_1, num_3, vc_2, vc_3, num_4)
            VALUES
                (l_id_pat_health_plan,
                 l_id_health_plan_entity,
                 l_desc_health_plan_entity,
                 l_id_health_plan,
                 l_desc_health_plan,
                 l_num_health_plan,
                 10);
        END LOOP;
    
        g_error := 'OPEN L_RET';
        SELECT num_health_plan
          INTO l_ret
          FROM (SELECT num_1 id_pat_health_plan,
                       num_2 id_health_plan_entity,
                       vc_1  desc_health_plan_entity,
                       num_2 id_health_plan,
                       vc_2  desc_health_plan,
                       vc_3  num_health_plan
                  FROM tbl_temp
                 WHERE num_2 = i_health_plan_entity
                   AND num_1 = i_health_plan)
         WHERE rownum = 1;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_BENEFICIARY_NUMBER',
                                              l_error);
            RETURN NULL;
    END get_patient_beneficiary_number;

    FUNCTION get_pat_exemptions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_current_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN t_tbl_core_domain IS
        l_current_date TIMESTAMP WITH LOCAL TIME ZONE := nvl(i_current_date, current_timestamp);
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ORDERS_UTILS.GET_PAT_EXEMPTIONS';
        c_valid_exemptions VARCHAR2(1 CHAR) := pk_sysconfig.get_config('ADT_VALID_EXEMPTIONS_WITH_NO_DATES', i_prof);
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        g_error := 'CALL ' || c_myfunction || ' FOR i_id_patient = ' || i_id_patient || ', ' ||
                   to_char(l_current_date, pk_alert_constant.g_dt_yyyymmddhh24miss);
        pk_alertlog.log_debug(g_error);
    
        --get all valid exemptions for the patient
        --exemptions with no effective_date and no expiration_date are considered not valid
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_isencao,
                                         domain_value  => id_pat_isencao,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT pi.id_pat_isencao,
                               pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || pi.id_isencao) desc_isencao
                          FROM pat_isencao pi
                         WHERE pi.id_patient = i_id_patient
                           AND pi.record_status != pk_alert_constant.g_inactive
                           AND (pi.flg_notif_status = pk_adt.c_notified_exemption OR
                               (pi.flg_notif_status = pk_adt.c_active_exemption AND
                               nvl(pi.expiration_date, l_current_date + 1) >= l_current_date AND
                               l_current_date >= nvl(pi.effective_date, l_current_date - 1) AND
                               (c_valid_exemptions = 'Y' OR
                               (pi.effective_date IS NOT NULL OR pi.expiration_date IS NOT NULL))))
                         ORDER BY desc_isencao));
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              l_error);
            RETURN l_ret;
    END get_pat_exemptions;

    FUNCTION get_pat_default_exemption
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_current_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_id_exemption   OUT pat_isencao.id_pat_isencao%TYPE,
        o_exemption_desc OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_current_date TIMESTAMP WITH LOCAL TIME ZONE := nvl(i_current_date, current_timestamp);
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ORDERS_UTILS.GET_PAT_DEFAULT_EXEMPTION';
        c_valid_exemptions VARCHAR2(1 CHAR) := pk_sysconfig.get_config('ADT_VALID_EXEMPTIONS_WITH_NO_DATES', i_prof);
    
        --  l_id_exemption pat_isencao.id_pat_isencao%type;
        --  l_exemption_desc   VARCHAR2(1000 CHAR);
        l_error t_error_out;
    BEGIN
    
        g_error := 'CALL ' || c_myfunction || ' FOR i_id_patient = ' || i_id_patient || ', ' ||
                   to_char(l_current_date, pk_alert_constant.g_dt_yyyymmddhh24miss);
        pk_alertlog.log_debug(g_error);
    
        BEGIN
            SELECT id_pat_isencao, desc_isencao
              INTO o_id_exemption, o_exemption_desc
              FROM (SELECT pi.id_pat_isencao,
                           pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || pi.id_isencao) desc_isencao
                      FROM pat_isencao pi
                     WHERE pi.id_patient = i_id_patient
                       AND pi.record_status != pk_alert_constant.g_inactive
                       AND (pi.flg_notif_status = pk_adt.c_notified_exemption OR
                           (pi.flg_notif_status = pk_adt.c_active_exemption AND
                           nvl(pi.expiration_date, l_current_date + 1) >= l_current_date AND
                           l_current_date >= nvl(pi.effective_date, l_current_date - 1) AND
                           (c_valid_exemptions = 'Y' OR
                           (pi.effective_date IS NOT NULL OR pi.expiration_date IS NOT NULL))))
                     ORDER BY desc_isencao)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_id_exemption   := NULL;
                o_exemption_desc := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              l_error);
            RETURN FALSE;
    END get_pat_default_exemption;

    FUNCTION get_multichoice_options
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_multichoice_type IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ORDERS_UTILS.get_multichoice_options';
        l_var   t_tbl_multichoice_option := NEW t_tbl_multichoice_option();
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        l_var := pk_multichoice.tf_multichoice_options(i_lang, i_prof, i_multichoice_type => i_multichoice_type);
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => t.label,
                                         domain_value  => t.data,
                                         order_rank    => t.rank,
                                         img_name      => NULL)
                  FROM (SELECT id_multichoice_option data, desc_option label, rank
                          FROM TABLE(l_var) mult_opts
                         ORDER BY mult_opts.rank ASC, mult_opts.desc_option) t);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              l_error);
            RETURN l_ret;
    END get_multichoice_options;

    FUNCTION get_priority_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_tbl_id_analysis    table_number;
        l_tbl_id_sample_type table_number;
        l_ret                t_tbl_core_domain;
        l_error              t_error_out;
    BEGIN
    
        g_error := 'OPEN L_RET';
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => label,
                                 domain_value  => data,
                                 order_rank    => rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT /*+opt_estimate(table s rows=1)*/
                 s.val data, s.rank, s.desc_val label
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      i_prof,
                                                                      CASE i_root_name
                                                                          WHEN pk_orders_constant.g_ds_lab_test_request THEN
                                                                           'ANALYSIS_REQ_DET.FLG_URGENCY'
                                                                          WHEN pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                           'EXAM_REQ.PRIORITY'
                                                                          WHEN pk_orders_constant.g_ds_other_exam_request THEN
                                                                           'EXAM_REQ.PRIORITY'
                                                                          WHEN pk_orders_constant.g_ds_procedure_request THEN
                                                                           'INTERV_PRESC_DET.FLG_PRTY'
                                                                          WHEN pk_orders_constant.g_ds_order_set_procedure THEN
                                                                           'INTERV_PRESC_DET.FLG_PRTY'
                                                                      END,
                                                                      NULL)) s
                 ORDER BY rank);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRIORITY_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_priority_list;

    FUNCTION get_time_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_default          IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain IS
        l_software  software.id_software%TYPE;
        l_flg_time  sys_config.value%TYPE;
        l_epis_type epis_type.id_epis_type%TYPE;
        l_config    sys_config.value%TYPE;
    
        l_area order_recurr_area.id_order_recurr_area%TYPE;
    
        l_ret   t_tbl_core_domain := t_tbl_core_domain();
        l_error t_error_out;
    BEGIN
    
        SELECT orp.id_order_recurr_area
          INTO l_area
          FROM order_recurr_plan orp
         WHERE orp.id_order_recurr_plan = i_id_order_recurr_plan;
    
        IF l_area = pk_order_recurrence_core.g_area_lab_test
        THEN
            IF i_id_episode IS NOT NULL
            THEN
                SELECT MAX(etsi.id_software) keep(dense_rank FIRST ORDER BY etsi.id_institution DESC) id_software
                  INTO l_software
                  FROM epis_type_soft_inst etsi
                  JOIN episode e
                    ON e.id_epis_type = etsi.id_epis_type
                 WHERE etsi.id_institution IN (0, i_prof.institution)
                   AND e.id_episode = i_id_episode;
            
                SELECT e.id_epis_type
                  INTO l_epis_type
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            END IF;
        
            l_flg_time := pk_sysconfig.get_config('LAB_FLG_TIME_E', i_prof.institution, i_prof.software);
        
            g_error := 'OPEN L_RET';
            SELECT t_row_core_domain(internal_name => NULL,
                                     desc_domain   => label,
                                     domain_value  => data,
                                     order_rank    => rank,
                                     img_name      => NULL)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT /*+opt_estimate(table s rows=1)*/
                     val data,
                     rank,
                     desc_val label,
                     decode(l_flg_time, val, pk_lab_tests_constant.g_yes, pk_lab_tests_constant.g_no) flg_default
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                          decode(l_epis_type,
                                                                                 NULL,
                                                                                 i_prof,
                                                                                 profissional(i_prof.id,
                                                                                              i_prof.institution,
                                                                                              l_software)),
                                                                          'ANALYSIS_REQ_DET.FLG_TIME_HARVEST',
                                                                          NULL)) s
                     WHERE val != pk_lab_tests_constant.g_flg_time_r)
             WHERE i_flg_default = pk_alert_constant.g_no
                OR (i_flg_default = pk_alert_constant.g_yes AND flg_default = pk_alert_constant.g_yes);
        ELSIF l_area = 13 --BLOOD PRODUCTS
        THEN
        
            l_ret := pk_blood_products_core.get_bp_time_list(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_episode       => i_id_episode,
                                                             i_internal_name => NULL,
                                                             o_error         => l_error);
        ELSIF l_area = pk_order_recurrence_core.g_area_procedure
        THEN
        
            l_flg_time := pk_sysconfig.get_config('FLG_TIME_E', i_prof.institution, i_prof.software);
        
            IF i_id_episode IS NOT NULL
            THEN
                SELECT e.id_epis_type
                  INTO l_epis_type
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
                SELECT MAX(etsi.id_software) keep(dense_rank FIRST ORDER BY etsi.id_institution DESC) id_software
                  INTO l_software
                  FROM epis_type_soft_inst etsi
                 WHERE etsi.id_institution IN (0, i_prof.institution)
                   AND etsi.id_epis_type = l_epis_type;
            END IF;
        
            g_error := 'OPEN L_RET';
            SELECT t_row_core_domain(internal_name => NULL,
                                     desc_domain   => label,
                                     domain_value  => data,
                                     order_rank    => rank,
                                     img_name      => NULL)
              BULK COLLECT
              INTO l_ret
              FROM ((SELECT val data,
                            rank,
                            desc_val label,
                            decode(l_flg_time, val, pk_procedures_constant.g_yes, pk_procedures_constant.g_no) flg_default
                       FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                           decode(l_epis_type,
                                                                                  NULL,
                                                                                  i_prof,
                                                                                  profissional(i_prof.id,
                                                                                               i_prof.institution,
                                                                                               l_software)),
                                                                           'INTERV_PRESCRIPTION.FLG_TIME',
                                                                           NULL))
                      WHERE val != pk_procedures_constant.g_flg_time_r))
             WHERE i_flg_default = pk_alert_constant.g_no
                OR (i_flg_default = pk_alert_constant.g_yes AND flg_default = pk_alert_constant.g_yes);
        ELSIF l_area IN (pk_order_recurrence_core.g_area_image_exam, pk_order_recurrence_core.g_area_other_exam)
        THEN
            IF l_area = pk_order_recurrence_core.g_area_image_exam
            THEN
                l_config := 'IMG_FLG_TIME_E';
            ELSE
                l_config := 'EXM_FLG_TIME_E';
            END IF;
        
            g_error    := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || l_config;
            l_flg_time := pk_sysconfig.get_config(l_config, i_prof.institution, i_prof.software);
        
            IF i_id_episode IS NOT NULL
            THEN
                SELECT e.id_epis_type
                  INTO l_epis_type
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
                SELECT MAX(etsi.id_software) keep(dense_rank FIRST ORDER BY etsi.id_institution DESC) id_software
                  INTO l_software
                  FROM epis_type_soft_inst etsi
                 WHERE etsi.id_institution IN (0, i_prof.institution)
                   AND etsi.id_epis_type = l_epis_type;
            END IF;
        
            SELECT t_row_core_domain(internal_name => NULL,
                                     desc_domain   => label,
                                     domain_value  => data,
                                     order_rank    => NULL,
                                     img_name      => NULL)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT val data,
                           rank,
                           desc_val label,
                           decode(l_flg_time, val, pk_exam_constant.g_yes, pk_exam_constant.g_no) flg_default
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                          decode(l_epis_type,
                                                                                 NULL,
                                                                                 i_prof,
                                                                                 profissional(i_prof.id,
                                                                                              i_prof.institution,
                                                                                              l_software)),
                                                                          'EXAM_REQ.FLG_TIME',
                                                                          NULL))
                     WHERE val != pk_exam_constant.g_flg_time_r)
             WHERE i_flg_default = pk_alert_constant.g_no
                OR (i_flg_default = pk_alert_constant.g_yes AND flg_default = pk_alert_constant.g_yes)
             ORDER BY rank, label;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_time_list;

    FUNCTION get_prn_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        IF i_root_name IN (pk_orders_constant.g_ds_lab_test_request,
                           pk_orders_constant.g_ds_imaging_exam_request,
                           pk_orders_constant.g_ds_other_exam_request,
                           pk_orders_constant.g_ds_procedure_request,
                           pk_orders_constant.g_ds_order_set_procedure)
        THEN
            g_error := 'OPEN L_RET';
            SELECT t_row_core_domain(internal_name => NULL,
                                     desc_domain   => label,
                                     domain_value  => data,
                                     order_rank    => rank,
                                     img_name      => NULL)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT /*+opt_estimate(table s rows=1)*/
                     s.val data, s.rank, s.desc_val label
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                          i_prof,
                                                                          CASE i_root_name
                                                                              WHEN pk_orders_constant.g_ds_lab_test_request THEN
                                                                               'ANALYSIS_REQ_DET.FLG_PRN'
                                                                              WHEN
                                                                               pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                               'EXAM_REQ_DET.FLG_PRN'
                                                                              WHEN pk_orders_constant.g_ds_other_exam_request THEN
                                                                               'EXAM_REQ_DET.FLG_PRN'
                                                                              WHEN pk_orders_constant.g_ds_procedure_request THEN
                                                                               'INTERV_PRESC_DET.FLG_PRN'
                                                                              WHEN pk_orders_constant.g_ds_order_set_procedure THEN
                                                                               'INTERV_PRESC_DET.FLG_PRN'
                                                                          END,
                                                                          NULL)) s
                     ORDER BY rank);
        ELSIF i_root_name = 'DS_BLOOD_PRODUCTS'
        THEN
            dbms_output.put_line('TODO');
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRN_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_prn_list;

    FUNCTION get_fasting_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        g_error := 'OPEN L_RET';
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => label,
                                 domain_value  => data,
                                 order_rank    => rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT /*+opt_estimate(table s rows=1)*/
                 s.val data, s.rank, s.desc_val label
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      i_prof,
                                                                      CASE i_root_name
                                                                          WHEN pk_orders_constant.g_ds_lab_test_request THEN
                                                                           'ANALYSIS_REQ_DET.FLG_FASTING'
                                                                          WHEN pk_orders_constant.g_ds_imaging_exam_request THEN
                                                                           'EXAM_REQ_DET.FLG_FASTING'
                                                                          WHEN pk_orders_constant.g_ds_other_exam_request THEN
                                                                           'EXAM_REQ_DET.FLG_FASTING'
                                                                      END,
                                                                      NULL)) s
                 ORDER BY rank);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FASTING_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_fasting_list;

    FUNCTION get_mandatory_items
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_root_name          IN VARCHAR2,
        i_tbl_id_pk          IN table_number,
        i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_id_ds_component    IN ds_cmpt_mkt_rel.id_ds_component_child%TYPE,
        i_ds_internal_name   IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        io_tbl_result        IN OUT t_tbl_ds_get_value,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_mandatory_items table_varchar := table_varchar();
        l_mandatory_items     VARCHAR2(1000) := NULL;
    
    BEGIN
    
        FOR i IN i_tbl_id_pk.first .. i_tbl_id_pk.last
        LOOP
            l_mandatory_items := NULL;
            FOR j IN io_tbl_result.first .. io_tbl_result.last
            LOOP
                IF io_tbl_result(j).flg_event_type = 'M'
                THEN
                    l_mandatory_items := l_mandatory_items || io_tbl_result(j).id_ds_cmpt_mkt_rel || '|';
                END IF;
            END LOOP;
        
            IF l_mandatory_items IS NOT NULL
            THEN
                io_tbl_result.extend();
                io_tbl_result(io_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_id_ds_cmpt_mkt_rel,
                                                                         id_ds_component    => i_id_ds_component,
                                                                         internal_name      => i_ds_internal_name,
                                                                         VALUE              => i_tbl_id_pk(i),
                                                                         value_clob         => NULL,
                                                                         min_value          => NULL,
                                                                         max_value          => NULL,
                                                                         desc_value         => l_mandatory_items,
                                                                         desc_clob          => NULL,
                                                                         id_unit_measure    => NULL,
                                                                         desc_unit_measure  => NULL,
                                                                         flg_validation     => pk_alert_constant.g_yes,
                                                                         err_msg            => NULL,
                                                                         flg_event_type     => 'A',
                                                                         flg_multi_status   => NULL,
                                                                         idx                => 1);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MANDATORY_ITEMS',
                                              o_error);
            RETURN FALSE;
    END get_mandatory_items;

    FUNCTION get_diagnosis_xml
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_tbl_id_diagnosis       IN table_number,
        i_tbl_id_alert_diagnosis IN table_number,
        i_tbl_diagnosis_desc     IN table_varchar
    ) RETURN CLOB IS
        l_ret CLOB := NULL;
        no_match EXCEPTION;
    BEGIN
        -- Check if i_tbl_id_diagnosis and i_tbl_id_alert_diagnosis have the same size
        IF i_tbl_id_diagnosis.count <> i_tbl_id_alert_diagnosis.count
        THEN
            RAISE no_match;
        END IF;
    
        IF i_tbl_id_diagnosis.count > 0
        THEN
            l_ret := '<EPIS_DIAGNOSES ID_PATIENT="' || i_id_patient || '" ID_EPISODE="' || i_id_episode ||
                     '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
        
            FOR k IN i_tbl_id_diagnosis.first .. i_tbl_id_diagnosis.last
            LOOP
                l_ret := l_ret || ' <DIAGNOSIS ID_DIAGNOSIS="' || i_tbl_id_diagnosis(k) || '" ID_ALERT_DIAG="' ||
                         i_tbl_id_alert_diagnosis(k) || '">
                                <DESC_DIAGNOSIS>' || i_tbl_diagnosis_desc(k) ||
                         '</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
            END LOOP;
        
            l_ret := l_ret || ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_match THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diagnosis_xml;

    FUNCTION process_multi_form
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_episode   IN NUMBER,
        i_patient   IN NUMBER,
        i_root_name IN VARCHAR2,
        o_result    IN OUT t_tbl_ds_get_value,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    
        l_tbl_id_ds_cmpt_mkt_rel table_number := table_number();
        l_tbl_id_ds_component    table_number := table_number();
        l_tbl_internal_name      table_varchar := table_varchar();
        l_total_idx              PLS_INTEGER := 0;
    
        l_value             VARCHAR2(4000 CHAR);
        l_desc_value        VARCHAR2(4000 CHAR);
        l_id_unit_measure   unit_measure.id_unit_measure%TYPE;
        l_desc_unit_measure translation.desc_lang_1%TYPE;
        l_min_value         ds_cmpt_mkt_rel.min_value%TYPE;
        l_max_value         ds_cmpt_mkt_rel.max_value%TYPE;
        l_value_clob        CLOB;
        l_desc_clob         CLOB;
        l_flg_event_type    VARCHAR2(1 CHAR);
        l_flg_validation    VARCHAR(1 CHAR);
        l_err_msg           VARCHAR2(1000 CHAR);
    
        --Variáveis para utilização nos campos de multichoice
        l_tbl_value      table_varchar := table_varchar();
        l_tbl_desc_value table_varchar := table_varchar();
    
        l_is_multiple    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_is_multichoice VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_is_mem         VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_section_type   VARCHAR2(1 CHAR) := NULL;
    
        --l_mandatory_warning BOOLEAN := FALSE;
        --l_message_mandatory CONSTANT sys_message.code_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M164');
        l_message_error CONSTANT sys_message.code_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M165');
        --l_count_mandatory_elements NUMBER(24);
        l_count_empty_items NUMBER(24);
        --l_has_mandatory_components VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
        --Funtion to check if it's a clob field.
        FUNCTION is_clob(i_id_ds_component IN ds_component.id_ds_component%TYPE) RETURN VARCHAR2 IS
        
            l_ret VARCHAR2(1) := NULL;
        BEGIN
            SELECT decode(d.flg_data_type, 'LO', pk_alert_constant.g_yes, pk_alert_constant.g_no)
              INTO l_ret
              FROM ds_component d
             WHERE d.id_ds_component = i_id_ds_component;
        
            RETURN l_ret;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN pk_alert_constant.g_no;
        END is_clob;
    
        --Function to check if the field allows multiple values (i.e. diagnosis field, multichoice options field)
        FUNCTION is_multichoice(i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN VARCHAR2 IS
        
            l_ret VARCHAR2(1) := NULL;
        BEGIN
            SELECT CASE
                       WHEN COUNT(1) = 0 THEN
                        pk_alert_constant.g_no
                       ELSE
                        pk_alert_constant.g_yes
                   END
              INTO l_ret
              FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                     t.idx
                      FROM TABLE(o_result) t
                     WHERE t.id_ds_cmpt_mkt_rel = i_id_ds_cmpt_mkt_rel
                     GROUP BY t.idx
                    HAVING COUNT(1) > 1);
        
            RETURN l_ret;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN pk_alert_constant.g_no;
        END is_multichoice;
    
        --Função para verificar se se trata de um campo MEM. No idx 0 é necessário retornar todos os valores.
        FUNCTION is_mem(i_id_ds_component IN ds_component.id_ds_component%TYPE) RETURN VARCHAR2 IS
        
            l_ret VARCHAR2(1) := NULL;
        BEGIN
            SELECT decode(d.flg_data_type, 'MEM', pk_alert_constant.g_yes, pk_alert_constant.g_no)
              INTO l_ret
              FROM ds_component d
             WHERE d.id_ds_component = i_id_ds_component;
        
            RETURN l_ret;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN pk_alert_constant.g_no;
        END is_mem;
    
        FUNCTION get_section_type(i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN VARCHAR2 IS
            l_ret VARCHAR2(1) := NULL;
        BEGIN
            SELECT dcmr_parent.flg_hidden
              INTO l_ret
              FROM ds_cmpt_mkt_rel dcmr
              JOIN ds_cmpt_mkt_rel dcmr_parent
                ON dcmr.id_ds_component_parent = dcmr_parent.id_ds_component_child
               AND dcmr_parent.internal_name_parent = i_root_name
             WHERE dcmr.id_ds_cmpt_mkt_rel = i_id_ds_cmpt_mkt_rel;
        
            RETURN l_ret;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_section_type;
    
    BEGIN
        IF o_result.count > 0
        THEN
            SELECT /*+ opt_estimate(table t rows=1)*/
            DISTINCT t.id_ds_cmpt_mkt_rel, t.id_ds_component, t.internal_name
              BULK COLLECT
              INTO l_tbl_id_ds_cmpt_mkt_rel, l_tbl_id_ds_component, l_tbl_internal_name
              FROM TABLE(o_result) t;
        
            FOR i IN l_tbl_id_ds_cmpt_mkt_rel.first .. l_tbl_id_ds_cmpt_mkt_rel.last
            LOOP
                --1º Passo - Determinar se os valores são todos iguais para cada id_ds_cmpt_mkt_rel.
            
                --Esta varíavel vai indicar se existem registos diferentes para o mesmo campo (ou seja, se cada elemento do carrinho
                --tem valores distintos para este campo. Não confundir com conceito de campos multichoice)
                --É necessário indicar esta informação ao UX para que apresente a tag '(Multiple)' nesses campos
                --O value, desc_value, value_clob e desc_clob tem que ser enviado a null nestes casos
                l_is_multiple := pk_alert_constant.g_no;
            
                --Determinar se o campo é de multichoice (i.e. se apresenta múltiplos valores como por exemplo nos diagnósticos)
                l_is_multichoice := is_multichoice(l_tbl_id_ds_cmpt_mkt_rel(i));
            
                --Determinar se o campo é de memória (é necessário devolver todos os valores no idx 0)
                l_is_mem := is_mem(l_tbl_id_ds_component(i));
            
                --Limpar o section type. O section type só é necessário para os campos de MM, para ver se pertencem a uma secção do tipo 'T'.
                l_section_type := NULL;
            
                IF l_is_multichoice = pk_alert_constant.g_yes
                   OR l_is_mem = pk_alert_constant.g_yes
                THEN
                    --Se se trata de um campo de multichoice com mais que um valor, é necessário determinar se este set de valores
                    --se encontra disponível para todos os elementos do carrinho
                
                    --Determinar número total de registos no carrinho
                    SELECT COUNT(1)
                      INTO l_total_idx
                      FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                            DISTINCT t.idx
                              FROM TABLE(o_result) t
                             WHERE t.idx <> 0);
                
                    --Como temos múltiplos valores, vai ser necessário aferir se este campo está inserido numa secção do tipo 'T'.
                    --(Esta secção está escondida, mas os valores dos seus campos não são eliminados pelo motor)
                    --O intuito desta verificação é garantir que o motor não limpa os dados duplicados para um determinado elemento do carrinho. Precisamos de todos os valores!
                    l_section_type := get_section_type(l_tbl_id_ds_cmpt_mkt_rel(i));
                
                    --Correr a estrutura para verificar se cada um dos valores no campo está disponível para todos os elementos do carrinho
                    --Se não estiverem, será necessário indicar ao UX que existem valores múltiplos neste campo
                    IF l_is_multichoice = pk_alert_constant.g_no
                    THEN
                        --De acordo com o UX, os campos de memória para o idx 0 devem ir com a flag_multiple a 'N' se só tivermos um registo no carrinho,
                        --ou com a flag_multiple a 'Y' caso existam vários registos no carrinho, mesmo que os valores do campo sejam iguais para todos os registos. 
                        IF l_is_mem = pk_alert_constant.g_yes
                        THEN
                            IF l_total_idx = 1
                            THEN
                                l_is_multiple := pk_alert_constant.g_no;
                            ELSE
                                l_is_multiple := pk_alert_constant.g_yes;
                            END IF;
                        ELSE
                            FOR j IN o_result.first .. o_result.last
                            LOOP
                                IF o_result(j).id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                                THEN
                                    SELECT /*+ opt_estimate(table t rows=1)*/
                                     COUNT(1)
                                      INTO l_count
                                      FROM TABLE(o_result) t
                                     WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                                       AND (t.value = o_result(j).value OR
                                           (t.value IS NULL AND o_result(j).value IS NULL));
                                
                                    IF l_count <> l_total_idx
                                    THEN
                                        l_value       := NULL;
                                        l_desc_value  := NULL;
                                        l_is_multiple := pk_alert_constant.g_yes;
                                        EXIT;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    ELSE
                        --Os elementos multichoice da secção 'T' devem ser sempre considerados como múltiplos
                        --para que o UX envie corretamente os valores no momento da gravação.
                        IF l_section_type <> 'T'
                        THEN
                            FOR j IN o_result.first .. o_result.last
                            LOOP
                                IF o_result(j).id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                                THEN
                                    SELECT COUNT(1)
                                      INTO l_count
                                      FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                                            DISTINCT t.value, t.idx
                                              FROM TABLE(o_result) t
                                             WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                                               AND (t.value = o_result(j).value OR
                                                   (t.value IS NULL AND o_result(j).value IS NULL)));
                                
                                    IF l_count <> l_total_idx
                                       AND l_total_idx > 1
                                    THEN
                                        l_value       := NULL;
                                        l_desc_value  := NULL;
                                        l_is_multiple := pk_alert_constant.g_yes;
                                        EXIT;
                                    END IF;
                                END IF;
                            END LOOP;
                        ELSE
                            l_value       := NULL;
                            l_desc_value  := NULL;
                            l_is_multiple := pk_alert_constant.g_yes;
                        END IF;
                    END IF;
                
                    --Determinar se o campo é clob para saber o que comparar   
                ELSIF is_clob(l_tbl_id_ds_component(i)) = pk_alert_constant.g_no
                THEN
                    --Se não for clob, é necessário comparar o value, desc_value e a unit_measure
                    SELECT COUNT(1)
                      INTO l_count
                      FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                            DISTINCT t.value, t.desc_value, t.id_unit_measure
                              FROM TABLE(o_result) t
                             WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i));
                
                    IF l_count > 1
                    THEN
                        l_value       := NULL;
                        l_desc_value  := NULL;
                        l_is_multiple := pk_alert_constant.g_yes;
                    END IF;
                ELSE
                    --Se for clob, é necessário comparar os dois campos de clob
                    SELECT COUNT(1)
                      INTO l_count
                      FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                            DISTINCT CASE
                                          WHEN nvl(length(t.value_clob), 0) > 0 THEN
                                           dbms_crypto.hash(t.value_clob, 2)
                                          ELSE
                                           NULL
                                      END value_clob,
                                     CASE
                                          WHEN nvl(length(t.desc_clob), 0) > 0 THEN
                                           dbms_crypto.hash(t.desc_clob, 2)
                                          ELSE
                                           NULL
                                      END desc_clob
                              FROM TABLE(o_result) t
                             WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i));
                    IF l_count > 1
                    THEN
                        l_value       := NULL;
                        l_desc_clob   := NULL;
                        l_value_clob  := NULL;
                        l_is_multiple := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            
                --Se l_is_multiple = 'N', então significa que os valores são todos iguais, como tal basta pegar no 1º para apresentar.
                IF l_is_multiple = pk_alert_constant.g_no
                   AND l_is_multichoice = pk_alert_constant.g_no
                   AND l_is_mem = pk_alert_constant.g_no
                THEN
                    SELECT VALUE,
                           desc_value,
                           id_unit_measure,
                           desc_unit_measure,
                           min_value,
                           max_value,
                           value_clob,
                           desc_clob
                      INTO l_value,
                           l_desc_value,
                           l_id_unit_measure,
                           l_desc_unit_measure,
                           l_min_value,
                           l_max_value,
                           l_value_clob,
                           l_desc_clob
                      FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                             t.value,
                             t.desc_value,
                             t.id_unit_measure,
                             t.desc_unit_measure,
                             t.min_value,
                             t.max_value,
                             t.value_clob,
                             t.desc_clob
                              FROM TABLE(o_result) t
                             WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i))
                     WHERE rownum = 1;
                
                ELSIF (l_is_multiple = pk_alert_constant.g_no AND l_is_multichoice = pk_alert_constant.g_yes)
                      AND l_section_type <> 'T'
                THEN
                    --Para os campos de multichoice é necessária a utilização de arrays para a definição dos value e dos desc_values,
                    --Para este tipo de campo, os valores de unit_measure, value_clob, min e max_value serão sempre null.
                    l_tbl_value      := table_varchar();
                    l_tbl_desc_value := table_varchar();
                
                    SELECT /*+ opt_estimate(table t rows=1)*/
                    DISTINCT t.value, t.desc_value
                      BULK COLLECT
                      INTO l_tbl_value, l_tbl_desc_value
                      FROM TABLE(o_result) t
                     WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i);
                ELSIF (l_is_multiple = pk_alert_constant.g_no AND l_is_multichoice = pk_alert_constant.g_yes)
                      AND l_section_type = 'T'
                THEN
                    --Para os campos de multichoice é necessária a utilização de arrays para a definição dos value e dos desc_values,
                    --Para este tipo de campo, os valores de unit_measure, value_clob, min e max_value serão sempre null.
                    l_tbl_value      := table_varchar();
                    l_tbl_desc_value := table_varchar();
                
                    SELECT /*+ opt_estimate(table t rows=1)*/
                     t.value, t.desc_value
                      BULK COLLECT
                      INTO l_tbl_value, l_tbl_desc_value
                      FROM TABLE(o_result) t
                     WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                       AND t.idx = 1;
                ELSIF l_is_mem = pk_alert_constant.g_yes
                THEN
                    --Memory fields should always show all the values, even if they are repeated
                    l_tbl_value      := table_varchar();
                    l_tbl_desc_value := table_varchar();
                
                    SELECT /*+ opt_estimate(table t rows=1)*/
                     t.value, t.desc_value
                      BULK COLLECT
                      INTO l_tbl_value, l_tbl_desc_value
                      FROM TABLE(o_result) t
                     WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i);
                ELSIF l_is_multiple = pk_alert_constant.g_yes
                THEN
                    --Para os campos com valores múltiplos, o value e o desc_value não são importantes, pois
                    --o que o UX vai apresentar é a tag 'Multiples'
                    --Contudo, é necessário continuar a saber se há valores min/max configurados
                    --E, uma vez que os valores múltiplos podem ter diferentes unidades de medida, setamos novamente 
                    --a unidade default do componente
                    SELECT d.id_unit_measure, d.min_value, d.max_value
                      INTO l_id_unit_measure, l_min_value, l_max_value
                      FROM ds_cmpt_mkt_rel d
                     WHERE d.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i);
                END IF;
            
                --2º Passo - Determinar o tipo de flag_event_type a apresentar no formulário múltiplo
                SELECT COUNT(1)
                  INTO l_count
                  FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                        DISTINCT decode(t.flg_event_type, NULL, pk_orders_constant.g_component_active, t.flg_event_type) flg_event_type
                          FROM TABLE(o_result) t
                         WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i));
            
                --Se l_count = 1 significa que todas as flags são iguais para o mesmo id_ds_cmpt_mkt_rel
                IF l_count = 1
                THEN
                    SELECT /*+ opt_estimate(table t rows=1)*/
                     decode(t.flg_event_type,
                            NULL,
                            pk_orders_constant.g_component_active,
                            pk_orders_constant.g_component_unique,
                            decode(l_is_multiple, pk_alert_constant.g_yes, 'R', 'A'),
                            t.flg_event_type) flg_event_type
                      INTO l_flg_event_type
                      FROM TABLE(o_result) t
                     WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                       AND rownum = 1;
                
                    --Se o elemento é obrigatório, e temos vários elementos no carrinho, é preciso verificar se
                    --todos os elementos têm valor nesse campo. Se estiverem todos preenchidos, é necessário
                    --indicao ao idx 0 que o campo não é obrigatório para não o mostrar a amarelo.
                    --Se houver pelo menos 1 elemento sem valor, então o idx 0 tem que continuar a ser obrigatório
                    --para mostrar o campo a amarelo e indicar que falta documentar informação.
                    IF l_is_multiple = pk_alert_constant.g_yes
                       AND l_flg_event_type = pk_orders_constant.g_component_mandatory
                    THEN
                        l_count_empty_items := 0;
                    
                        FOR j IN o_result.first .. o_result.last
                        LOOP
                            IF (o_result(j).value IS NULL OR o_result(j).value = '')
                               AND o_result(j).id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                            THEN
                                l_count_empty_items := l_count_empty_items + 1;
                            END IF;
                        END LOOP;
                    
                        IF l_count_empty_items = 0
                        THEN
                            l_flg_event_type := pk_orders_constant.g_component_active;
                        END IF;
                    END IF;
                ELSE
                    --Se l_count > 1 significa que temos diferentes flags dentro do mesmo id_ds_cmpt_mkt_rel. É necessário
                    --definir um peso para as diferentes flags possíveis, tendo sido decidida esta ordem (de maior importância para menor)
                    --'I' - Inactivo
                    --'R' - Read-only
                    --'M' - Mandatory
                    --'A' - Active 
                    --'H' - Hidden
                    --A flag com maior peso será a flag a ser apresentada no formulário múltiplo.
                    --Nota: Os campos definidos com 'I' apagam o seu conteúdo, assim, para não se perder o descritivo de múltiplo (quando disponível),
                    --a flag 'I' será apresentada como 'R'. O mesmo acontece para os registos com a flag H.
                    SELECT decode(flg_event_type,
                                  'I',
                                  'R',
                                  'H',
                                  'R',
                                  'U',
                                  decode(l_is_multiple, pk_alert_constant.g_yes, 'R', 'A'),
                                  NULL,
                                  'A',
                                  flg_event_type)
                      INTO l_flg_event_type
                      FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                             t.flg_event_type,
                             decode(t.flg_event_type, 'A', 40, 'U', 40, NULL, 40, 'M', 30, 'R', 20, 'I', 10, 'H', 10, 0) rank
                              FROM TABLE(o_result) t
                             WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                             ORDER BY rank)
                     WHERE rownum = 1;
                
                    --Se o elemento é obrigatório, e temos vários elementos no carrinho, é preciso verificar se
                    --todos os elementos OBRIGATÓRIOS têm valor nesse campo. Se estiverem todos preenchidos, é necessário
                    --indicao ao idx 0 que o campo não é obrigatório para não o mostrar a amarelo.
                    --Se houver pelo menos 1 elemento sem valor, então o idx 0 tem que continuar a ser obrigatório
                    --para mostrar o campo a amarelo e indicar que falta documentar informação.
                    IF l_is_multiple = pk_alert_constant.g_yes
                       AND l_flg_event_type = pk_orders_constant.g_component_mandatory
                    THEN
                        l_count_empty_items := 0;
                    
                        FOR j IN o_result.first .. o_result.last
                        LOOP
                            IF (o_result(j).value IS NULL OR o_result(j).value = '')
                               AND o_result(j).id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                               AND o_result(j).flg_event_type = pk_orders_constant.g_component_mandatory
                            THEN
                                l_count_empty_items := l_count_empty_items + 1;
                            END IF;
                        END LOOP;
                    
                        IF l_count_empty_items = 0
                        THEN
                            l_flg_event_type := pk_orders_constant.g_component_active;
                        END IF;
                    END IF;
                END IF;
            
                --3º PASSO: Verificar se a flag_validation e a mensagem de erro é igual para todos os elementos do carrinho.
                --Se forem todas iguais, o idx 0 assume a mesma flg_validation e error_message.
                --Se existirem elementos no carrinho com erro e outros sem erro, o idx 0 vai assumir erro genérico.
                SELECT COUNT(1)
                  INTO l_count
                  FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                        DISTINCT decode(t.flg_validation, NULL, pk_alert_constant.g_yes, t.flg_validation) flg_validation,
                                 t.err_msg
                          FROM TABLE(o_result) t
                         WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i));
            
                IF l_count = 1
                THEN
                    --Sendo igual para todos, apresenta-se a flag e a mensagem do 1º para o formulário múltiplo
                    SELECT /*+ opt_estimate(table t rows=1)*/
                     t.flg_validation, t.err_msg
                      INTO l_flg_validation, l_err_msg
                      FROM TABLE(o_result) t
                     WHERE t.id_ds_cmpt_mkt_rel = l_tbl_id_ds_cmpt_mkt_rel(i)
                       AND rownum = 1;
                ELSE
                    --Se existem diferentes flags e/ou mensagens, indica-se que há um erro no campo
                    --e apresenta-se a mensagem de erro genérica
                    l_flg_validation := 'E';
                    l_err_msg        := l_message_error;
                END IF;
            
                --4º PASSO - Incrementar o cursor com o elemento dummy (idx = 0)
                IF (l_is_multichoice = pk_alert_constant.g_no AND l_is_mem = pk_alert_constant.g_no)
                   OR (l_is_multichoice = pk_alert_constant.g_yes AND l_is_multiple = pk_alert_constant.g_yes)
                THEN
                    o_result.extend();
                    o_result(o_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => l_tbl_id_ds_cmpt_mkt_rel(i),
                                                                   id_ds_component    => l_tbl_id_ds_component(i),
                                                                   internal_name      => l_tbl_internal_name(i),
                                                                   VALUE              => l_value,
                                                                   value_clob         => l_value_clob,
                                                                   min_value          => l_min_value,
                                                                   max_value          => l_max_value,
                                                                   desc_value         => l_desc_value,
                                                                   desc_clob          => l_desc_clob,
                                                                   id_unit_measure    => l_id_unit_measure,
                                                                   desc_unit_measure  => l_desc_unit_measure,
                                                                   flg_validation     => l_flg_validation,
                                                                   err_msg            => l_err_msg,
                                                                   flg_event_type     => l_flg_event_type,
                                                                   flg_multi_status   => l_is_multiple,
                                                                   idx                => 0);
                ELSE
                    --Se se tratar de um campo de multichoice onde o set de valores é igual para todos os elementos do carrinho,
                    --então é necessário percorrer o array de value e desc_value para enviar ao UX.
                    FOR j IN l_tbl_value.first .. l_tbl_value.last
                    LOOP
                        o_result.extend();
                        o_result(o_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => l_tbl_id_ds_cmpt_mkt_rel(i),
                                                                       id_ds_component    => l_tbl_id_ds_component(i),
                                                                       internal_name      => l_tbl_internal_name(i),
                                                                       VALUE              => l_tbl_value(j),
                                                                       value_clob         => l_value_clob,
                                                                       min_value          => l_min_value,
                                                                       max_value          => l_max_value,
                                                                       desc_value         => l_tbl_desc_value(j),
                                                                       desc_clob          => l_desc_clob,
                                                                       id_unit_measure    => l_id_unit_measure,
                                                                       desc_unit_measure  => l_desc_unit_measure,
                                                                       flg_validation     => l_flg_validation,
                                                                       err_msg            => l_err_msg,
                                                                       flg_event_type     => l_flg_event_type,
                                                                       flg_multi_status   => CASE
                                                                                                 WHEN l_section_type = 'T' THEN
                                                                                                 --O UX precisa que nestes campos MEM (T e de EVAL) este parâmetro vá sempre a 'N'
                                                                                                  pk_alert_constant.g_no
                                                                                                 ELSE
                                                                                                  l_is_multiple
                                                                                             END,
                                                                       idx                => 0);
                    END LOOP;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    FUNCTION get_mcdt_documents_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_req_det   IN NUMBER,
        i_mcdt_type IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_mcdt_type IN (pk_exam_constant.g_type_img, pk_exam_constant.g_type_exm)
        THEN
            g_error := 'CALL GET_EXAM_DOCUMENTS_LIST';
            IF NOT pk_exam_core.get_exam_documents_list(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_exam_req_det => i_req_det,
                                                        o_list         => o_list,
                                                        o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MCDT_DOCUMENTS_LIST',
                                              o_error);
            RETURN FALSE;
    END get_mcdt_documents_list;

    FUNCTION get_unit_measure_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        l_error t_error_out;
    BEGIN
    
        g_error := 'ERROR CALLING PK_UNIT_MEASURE.TF_GET_UNIT_MEASURE_LIST';
        RETURN pk_unit_measure.tf_get_unit_measure_list(i_lang => i_lang, i_prof => i_prof, i_area => i_root_name);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_UNIT_MEASURE_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_unit_measure_list;

    FUNCTION get_catalogue_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2,
        i_records   IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_error t_error_out;
    
    BEGIN
    
        IF i_root_name IN (pk_orders_constant.g_ds_procedure_request, pk_orders_constant.g_ds_order_set_procedure)
        THEN
            RETURN pk_procedures_core.get_procedure_codification_list(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_intervention => i_records);
        ELSIF i_root_name IN (pk_orders_constant.g_ds_imaging_exam_request, pk_orders_constant.g_ds_other_exam_request)
        THEN
            RETURN pk_exam_core.get_exam_codification_list(i_lang => i_lang, i_prof => i_prof, i_exams => i_records);
        ELSE
            RETURN t_tbl_core_domain();
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CATALOGUE_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_catalogue_list;

    FUNCTION get_location_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2,
        i_records   IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_tbl_records table_number := table_number();
    
        l_error t_error_out;
    
    BEGIN
    
        l_tbl_records := pk_utils.str_split_n(i_list => i_records, i_delim => '|');
    
        IF i_root_name IN (pk_orders_constant.g_ds_imaging_exam_request, pk_orders_constant.g_ds_other_exam_request)
        THEN
            RETURN pk_exam_core.get_exam_location(i_lang => i_lang, i_prof => i_prof, i_exams => l_tbl_records);
        ELSE
            RETURN t_tbl_core_domain();
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LOCATION_LIST',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_location_list;

    FUNCTION get_alert_languages
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_return t_tbl_core_domain := t_tbl_core_domain();
    
        l_error t_error_out;
    BEGIN
        g_error := 'OPEN L_RETURN';
        SELECT *
          BULK COLLECT
          INTO l_return
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT id_language data, desc_val label
                          FROM ( -- Default language
                                SELECT to_number(val) id_language,
                                        desc_val,
                                        pk_alert_constant.g_yes flg_select,
                                        9 order_field
                                  FROM sys_domain s
                                 WHERE s.code_domain = 'LANGUAGE'
                                   AND s.domain_owner = pk_sysdomain.k_default_schema
                                   AND s.val IN (SELECT psa.id_language
                                                   FROM pat_soc_attributes psa
                                                  WHERE psa.id_patient = i_id_patient)
                                   AND s.id_language = i_lang
                                UNION
                                -- Other languages
                                SELECT to_number(val) id_language,
                                        desc_val,
                                        pk_alert_constant.g_no flg_select,
                                        9 order_field
                                  FROM sys_domain s
                                 WHERE s.code_domain = 'LANGUAGE'
                                   AND s.domain_owner = pk_sysdomain.k_default_schema
                                      -- Faster than an IN or EXISTS
                                   AND (SELECT COUNT(1)
                                          FROM pat_soc_attributes psa
                                         WHERE (psa.id_language IS NOT NULL AND psa.id_language = s.val)
                                           AND psa.id_patient = i_id_patient) = 0
                                   AND s.id_language = i_lang)
                         ORDER BY order_field, label ASC));
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ALERT_LANGUAGES',
                                              o_error    => l_error);
            RETURN t_tbl_core_domain();
        
    END get_alert_languages;

    FUNCTION get_laterality_event_type
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_root_name            IN VARCHAR2,
        i_laterality_mandatory IN sys_config.value%TYPE,
        i_idx                  IN NUMBER DEFAULT 1,
        i_value_laterality     IN VARCHAR2,
        i_tbl_data             IN table_table_varchar
    ) RETURN VARCHAR2 IS
    
        l_tbl_distinct_lateralities table_varchar := table_varchar();
    
        l_count PLS_INTEGER := 0;
    
        l_ret VARCHAR2(1 CHAR);
    
    BEGIN
        IF i_root_name IN (pk_orders_constant.g_ds_procedure_request,
                           pk_orders_constant.g_ds_order_set_procedure,
                           pk_orders_constant.g_ds_imaging_exam_request,
                           pk_orders_constant.g_ds_other_exam_request)
        THEN
            FOR i IN i_tbl_data.first .. i_tbl_data.last
            LOOP
                l_tbl_distinct_lateralities := l_tbl_distinct_lateralities MULTISET UNION DISTINCT
                                               table_varchar(i_tbl_data(i) (3));
            END LOOP;
        END IF;
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                DISTINCT t.column_value
                  FROM TABLE(l_tbl_distinct_lateralities) t
                 WHERE t.column_value NOT IN ('O', 'A'));
    
        IF l_count > 1
        THEN
            l_ret := CASE
                         WHEN i_value_laterality IS NOT NULL THEN
                          pk_orders_constant.g_component_read_only
                         ELSE
                          CASE i_laterality_mandatory
                              WHEN pk_alert_constant.g_yes THEN
                               pk_orders_constant.g_component_mandatory
                              ELSE
                               pk_orders_constant.g_component_active
                          END
                     END;
        ELSE
            l_ret := CASE i_laterality_mandatory
                         WHEN pk_alert_constant.g_yes THEN
                          pk_orders_constant.g_component_mandatory
                         ELSE
                          pk_orders_constant.g_component_active
                     END;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_orders_constant.g_component_active;
    END;

    FUNCTION get_prof_institutions
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_ret t_tbl_core_domain;
    
        l_tbl_inst   table_number := table_number();
        l_count_inst PLS_INTEGER := 0;
    
    BEGIN
    
        g_error := 'ERROR CALLING PK_UTILS.GET_INSTITUTIONS_SIB';
        IF NOT pk_utils.get_institutions_sib(i_lang  => i_lang,
                                             i_prof  => i_prof,
                                             i_inst  => i_prof.institution,
                                             o_list  => l_tbl_inst,
                                             o_error => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_count_inst := l_tbl_inst.count;
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => t.desc_val,
                                         domain_value  => t.val,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT i.id_institution val,
                               2 rank,
                               pk_translation.get_translation(i_lang, i.code_institution) desc_val
                          FROM institution i
                          JOIN prof_institution pi
                            ON pi.id_institution = i.id_institution
                           AND pi.id_professional = i_prof.id
                         WHERE i.id_institution IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                     *
                                                      FROM TABLE(l_tbl_inst) t)
                           AND pi.flg_state = pk_alert_constant.g_active
                           AND pi.dt_end_tstz IS NULL
                        UNION ALL
                        SELECT -1 id_institution, 1 rank, pk_message.get_message(i_lang, 'COMMON_M014') desc_val
                          FROM dual
                         WHERE l_count_inst > 1) t
                 ORDER BY rank, desc_val);
    
        RETURN l_ret;
    
    EXCEPTION
        -- Unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_INSTITUTIONS',
                                              o_error);
            RETURN t_tbl_core_domain();
    END get_prof_institutions;

    FUNCTION set_merge_pat_exemption
    (
        i_lang     language.id_language%TYPE,
        i_prof     profissional,
        i_pat      patient.id_patient%TYPE,
        i_pat_temp patient.id_patient%TYPE,
        o_error    t_error_out
    ) RETURN BOOLEAN AS
        l_id_p_i         table_number;
        l_id_i           table_number;
        l_id_pat_isencao pat_isencao.id_pat_isencao%TYPE;
    BEGIN
    
        SELECT a.id_pat_isencao, a.id_isencao
          BULK COLLECT
          INTO l_id_p_i, l_id_i
          FROM pat_isencao a
         WHERE a.id_patient = i_pat_temp;
    
        FOR i IN 1 .. l_id_p_i.count
        LOOP
            SELECT id_pat_isencao
              INTO l_id_pat_isencao
              FROM pat_isencao
             WHERE id_patient = i_pat
               AND id_isencao = l_id_i(i);
        
            UPDATE exam_req_det a
               SET a.id_pat_exemption = l_id_pat_isencao
             WHERE a.id_pat_exemption = l_id_p_i(i);
        
            UPDATE analysis_req_det a
               SET a.id_pat_exemption = l_id_pat_isencao
             WHERE a.id_pat_exemption = l_id_p_i(i);
        
            UPDATE interv_presc_det a
               SET a.id_pat_exemption = l_id_pat_isencao
             WHERE a.id_pat_exemption = l_id_p_i(i);
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END set_merge_pat_exemption;

    FUNCTION get_object_info
    (
        i_object_name IN VARCHAR2,
        o_object_info OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
        l_object       table_varchar := table_varchar();
        l_package_name VARCHAR2(4000 CHAR);
        l_object_name  VARCHAR2(4000 CHAR);
    
        l_tbl_overload table_varchar := table_varchar();
    
        l_count PLS_INTEGER := 0;
    
        l_ret table_varchar := table_varchar();
    
        CURSOR c_object_info
        (
            i_package_name VARCHAR2,
            i_object_name  VARCHAR2,
            i_overload     VARCHAR2
        ) IS
            SELECT aa.*
              FROM sys.all_procedures ap
              JOIN sys.all_arguments aa
                ON aa.owner = ap.owner
               AND aa.object_name = ap.procedure_name
               AND aa.package_name = ap.object_name
               AND ap.overload = aa.overload
             WHERE ap.object_name = i_package_name
               AND ap.procedure_name = i_object_name
               AND ((aa.overload IS NULL AND i_overload IS NULL) OR aa.overload = i_overload)
               AND aa.argument_name IS NOT NULL
             ORDER BY aa.position;
    
        l_row_object_info c_object_info%ROWTYPE;
    
        FUNCTION get_object_type
        (
            i_package_name VARCHAR2,
            i_object_name  VARCHAR2,
            i_overload     VARCHAR2
        ) RETURN VARCHAR IS
            l_type VARCHAR2(4000 CHAR);
            l_ret  VARCHAR2(4000 CHAR);
        BEGIN
        
            SELECT aa.pls_type
              INTO l_type
              FROM sys.all_procedures ap
              JOIN sys.all_arguments aa
                ON aa.owner = ap.owner
               AND aa.object_name = ap.procedure_name
               AND aa.package_name = ap.object_name
               AND ap.overload = aa.overload
             WHERE ap.object_name = i_package_name
               AND ap.procedure_name = i_object_name
               AND ((aa.overload IS NULL AND i_overload IS NULL) OR aa.overload = i_overload)
               AND aa.argument_name IS NULL;
        
            IF l_type IS NOT NULL
            THEN
                l_ret := ' return ' || lower(l_type);
            ELSE
                l_ret := NULL;
            END IF;
        
            RETURN l_ret;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_object_type;
    
    BEGIN
        pk_alertlog.log_error('i_object_name: ' || i_object_name);
    
        l_object := pk_string_utils.str_split(i_list => i_object_name, i_delim => '.');
    
        l_package_name := l_object(1);
        l_object_name  := l_object(2);
    
        SELECT *
          BULK COLLECT
          INTO l_tbl_overload
          FROM (SELECT ap.overload
                  FROM sys.all_procedures ap
                 WHERE ap.object_name = l_package_name
                   AND ap.procedure_name = l_object_name
                 ORDER BY ap.overload);
    
        FOR i IN l_tbl_overload.first .. l_tbl_overload.last
        LOOP
            l_ret.extend();
            l_count := 0;
        
            OPEN c_object_info(l_package_name, l_object_name, l_tbl_overload(i));
        
            l_ret(l_ret.count) := lower(i_object_name) || '(';
        
            LOOP
                FETCH c_object_info
                    INTO l_row_object_info;
                EXIT WHEN c_object_info%NOTFOUND;
            
                IF l_count > 0
                THEN
                    l_ret(l_ret.count) := l_ret(l_ret.count) || ', ';
                END IF;
            
                l_ret(l_ret.count) := l_ret(l_ret.count) || lower(l_row_object_info.argument_name) || ' ' ||
                                      lower(coalesce(l_row_object_info.type_name, l_row_object_info.data_type));
            
                l_count := l_count + 1;
            END LOOP;
        
            l_ret(l_ret.count) := l_ret(l_ret.count) || ')' ||
                                  get_object_type(l_package_name, l_object_name, l_tbl_overload(i));
        
            CLOSE c_object_info;
        END LOOP;
    
        OPEN o_object_info FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.*
              FROM TABLE(l_ret) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_object_info;

    FUNCTION get_co_sign_values
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_episode      IN NUMBER,
        i_patient      IN NUMBER,
        i_root_name    IN VARCHAR2,
        i_idx          IN NUMBER DEFAULT 1,
        i_tbl_id_pk    IN table_number,
        i_tbl_mkt_rel  IN table_number,
        i_tbl_int_name IN table_varchar,
        i_value        IN table_table_varchar,
        i_value_mea    IN table_table_varchar,
        i_value_desc   IN table_table_varchar,
        i_tbl_data     IN table_table_varchar,
        i_value_clob   IN table_clob,
        i_tbl_result   IN OUT t_tbl_ds_get_value,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_ds_component ds_component.id_ds_component%TYPE;
    
        l_id_order_type     order_type.id_order_type%TYPE;
        l_default_prof      t_tbl_core_domain;
        l_id_default_prof   professional.id_professional%TYPE;
        l_default_prof_name professional.name%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        l_id_order_type := to_number(pk_orders_utils.get_value(pk_orders_constant.g_ds_order_type,
                                                               i_tbl_mkt_rel,
                                                               i_value));
        l_default_prof  := pk_co_sign.get_prof_list(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_id_episode       => i_episode,
                                                    i_id_order_type    => l_id_order_type,
                                                    i_internal_name    => NULL,
                                                    i_flg_show_default => pk_alert_constant.g_yes,
                                                    o_error            => o_error);
    
        IF l_default_prof.exists(1)
        THEN
            l_id_default_prof   := to_number(l_default_prof(1).domain_value);
            l_default_prof_name := l_default_prof(1).desc_domain;
        END IF;
    
        FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
        LOOP
            IF i_tbl_int_name(i) = pk_orders_constant.g_ds_ordered_by
               AND l_id_default_prof IS NOT NULL
            THEN
                l_id_ds_component := pk_orders_utils.get_id_ds_component(i_tbl_mkt_rel(i));
            
                i_tbl_result.extend();
                i_tbl_result(i_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                       id_ds_component    => l_id_ds_component,
                                                                       internal_name      => i_tbl_int_name(i),
                                                                       VALUE              => to_char(l_id_default_prof),
                                                                       value_clob         => NULL,
                                                                       min_value          => NULL,
                                                                       max_value          => NULL,
                                                                       desc_value         => l_default_prof_name,
                                                                       desc_clob          => NULL,
                                                                       id_unit_measure    => NULL,
                                                                       desc_unit_measure  => NULL,
                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                       err_msg            => NULL,
                                                                       flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                       flg_multi_status   => NULL,
                                                                       idx                => i_idx);
            
            ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_ordered_at
            THEN
                --The 'Ordered at' field should only be updated if it isn't empty
                IF i_value(i) (1) IS NULL
                THEN
                    i_tbl_result.extend();
                    i_tbl_result(i_tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                           id_ds_component    => l_id_ds_component,
                                                                           internal_name      => i_tbl_int_name(i),
                                                                           VALUE              => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                                             i_date => g_sysdate_tstz,
                                                                                                                             i_prof => i_prof),
                                                                           value_clob         => NULL,
                                                                           min_value          => NULL,
                                                                           max_value          => NULL,
                                                                           desc_value         => NULL,
                                                                           desc_clob          => NULL,
                                                                           id_unit_measure    => NULL,
                                                                           desc_unit_measure  => NULL,
                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                           err_msg            => NULL,
                                                                           flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                           flg_multi_status   => NULL,
                                                                           idx                => i_idx);
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_co_sign_values;

    FUNCTION get_prof_bleep_info
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PROF_BLEEP_INFO';
    
        l_work_phone   professional.work_phone%TYPE;
        l_cell_phone   professional.cell_phone%TYPE;
        l_bleep_number professional.bleep_number%TYPE;
    
        --Return variable
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
    BEGIN
        IF i_action IS NULL
        THEN
            SELECT p.work_phone, p.cell_phone, p.bleep_number
              INTO l_work_phone, l_cell_phone, l_bleep_number
              FROM professional p
             WHERE p.id_professional = i_prof.id;
        
            g_error := 'SELECT INTO TBL_RESULT';
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_work_phone_ft THEN
                                                                  l_work_phone
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_mobile_phone_ft THEN
                                                                  l_cell_phone
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_bleep_number THEN
                                                                  l_bleep_number
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_work_phone_ft THEN
                                                                  l_work_phone
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_mobile_phone_ft THEN
                                                                  l_cell_phone
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_bleep_number THEN
                                                                  l_bleep_number
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => pk_orders_constant.g_component_active,
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN (pk_orders_constant.g_ds_work_phone_ft,
                                       pk_orders_constant.g_ds_mobile_phone_ft,
                                       pk_orders_constant.g_ds_bleep_number)
             ORDER BY t.rn;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_prof_bleep_info;

    /********************************************************************************************
    * Get the task type of the clinical questions
    *
    * @param      i_lang                        Language
    * @param      i_prof                        Profissional identifier
    * @param      i_clinical_question_info      Clinical question information (TaskType|IdTask_IdQuestionnaire_IdSampleType)
    *    
    * @return     Task type of the clinical question (P-Procedure/A-Lab test/I-Imaging exam etc.)
    **********************************************************************************************/

    FUNCTION get_cq_task_type
    (
        i_lang                   IN NUMBER,
        i_prof                   IN profissional,
        i_clinical_question_info IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(10 CHAR) := NULL;
    BEGIN
    
        IF i_clinical_question_info IS NOT NULL
        THEN
            l_ret := substr(i_clinical_question_info, 1, instr(i_clinical_question_info, '|', 1) - 1);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cq_task_type;

    /********************************************************************************************
    * Get the id of the clinical question info string
    *
    * @param      i_lang                        Language
    * @param      i_prof                        Profissional identifier
    * @param      i_clinical_question_info      Clinical question information (TaskType|IdTask_IdQuestionnaire_IdSampleType)
    * @param      i_index                       Index  
    *
    * @return     Returns the id of the given index
    **********************************************************************************************/

    FUNCTION get_cq_id
    (
        i_lang                   IN NUMBER,
        i_prof                   IN profissional,
        i_clinical_question_info IN VARCHAR2,
        i_index                  IN NUMBER
    ) RETURN NUMBER IS
        l_ret       NUMBER(24) := NULL;
        l_pos_init  PLS_INTEGER := 0;
        l_pos_final PLS_INTEGER := 0;
    BEGIN
    
        IF i_clinical_question_info IS NOT NULL
           AND i_index > 0
        THEN
            IF i_index = 1
            THEN
                l_ret := to_number(substr(i_clinical_question_info, 3, instr(i_clinical_question_info, '_') - 3));
            ELSE
                l_pos_init  := instr(i_clinical_question_info, '_', 1, i_index - 1);
                l_pos_final := instr(i_clinical_question_info, '_', 1, i_index);
            
                IF l_pos_final = 0
                THEN
                    l_ret := to_number(substr(i_clinical_question_info, l_pos_init + 1));
                ELSE
                    l_ret := to_number(substr(i_clinical_question_info, l_pos_init + 1, (l_pos_final - l_pos_init) - 1));
                END IF;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_cq_id;

    /* ###################################################################################################################
    # Functions and procedures beyond this point should not be sent to stable version.                                   #  
    # These are only meant for development environments.                                                                 #  
    ######################################################################################################################*/
    PROCEDURE migrate_dynamic_screens
    (
        i_root          IN VARCHAR2,
        i_market_origin IN market.id_market%TYPE,
        i_market_dest   IN market.id_market%TYPE
    ) IS
    
        CURSOR c_ds_cmpt_mkt_rel
        (
            i_root_name      ds_component.internal_name%TYPE,
            i_id_market      market.id_market%TYPE,
            i_id_market_dest market.id_market%TYPE
        ) IS
            SELECT id_ds_cmpt_mkt_rel
              FROM ds_component dscp
              JOIN (SELECT d.id_ds_cmpt_mkt_rel,
                           d.id_market,
                           d.id_ds_component_parent,
                           d.internal_name_parent,
                           d.flg_component_type_parent,
                           d.id_ds_component_child,
                           d.internal_name_child,
                           d.flg_component_type_child,
                           d.rank,
                           d.flg_def_event_type
                      FROM ds_cmpt_mkt_rel d
                    --Left join com o market_dest para garantir que não se duplicam registos
                    --os blocos podem ser reutilizados em diferentes forms, se o bloco já tiver sido 
                    --criado para outro, não podemos estar a duplicar
                      LEFT JOIN ds_cmpt_mkt_rel d_c
                        ON (d_c.id_ds_component_parent = d.id_ds_component_parent OR d.id_ds_component_parent IS NULL)
                       AND d_c.id_ds_component_child = d.id_ds_component_child
                       AND d_c.id_market = i_id_market_dest
                     WHERE d.id_market = i_id_market
                       AND d.id_software = 0
                       AND d_c.id_ds_cmpt_mkt_rel IS NULL) dscm
                ON dscp.id_ds_component = dscm.id_ds_component_child
            CONNECT BY PRIOR dscm.id_ds_component_child = dscm.id_ds_component_parent
             START WITH dscm.internal_name_child IN (i_root_name)
             ORDER SIBLINGS BY dscm.rank;
    
        CURSOR c_ds_event
        (
            i_root_name ds_component.internal_name%TYPE,
            i_id_market market.id_market%TYPE
        ) IS
            SELECT t.id_ds_cmpt_mkt_rel
              FROM (SELECT id_ds_cmpt_mkt_rel
                      FROM ds_component dscp
                      JOIN (SELECT d.id_ds_cmpt_mkt_rel,
                                  d.id_market,
                                  d.id_ds_component_parent,
                                  d.internal_name_parent,
                                  d.flg_component_type_parent,
                                  d.id_ds_component_child,
                                  d.internal_name_child,
                                  d.flg_component_type_child,
                                  d.rank,
                                  d.flg_def_event_type
                             FROM ds_cmpt_mkt_rel d
                            WHERE d.id_market = i_id_market
                              AND d.id_software = 0) dscm
                        ON dscp.id_ds_component = dscm.id_ds_component_child
                    CONNECT BY PRIOR dscm.id_ds_component_child = dscm.id_ds_component_parent
                     START WITH dscm.internal_name_child IN (i_root_name)
                     ORDER SIBLINGS BY dscm.rank) t
              JOIN ds_event de
                ON de.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel;
    
        CURSOR c_ds_cmpt_mkt_rel_service
        (
            i_root_name ds_component.internal_name%TYPE,
            i_id_market market.id_market%TYPE
        ) IS
            SELECT id_ds_cmpt_mkt_rel, dscm.service_params
              FROM ds_component dscp
              JOIN (SELECT d.id_ds_cmpt_mkt_rel,
                           d.id_market,
                           d.id_ds_component_parent,
                           d.internal_name_parent,
                           d.flg_component_type_parent,
                           d.id_ds_component_child,
                           d.internal_name_child,
                           d.flg_component_type_child,
                           d.rank,
                           d.flg_def_event_type,
                           d.service_params
                      FROM ds_cmpt_mkt_rel d
                     WHERE d.id_market = i_id_market
                       AND d.id_software = 0) dscm
                ON dscp.id_ds_component = dscm.id_ds_component_child
             WHERE dscm.service_params IS NOT NULL
            CONNECT BY PRIOR dscm.id_ds_component_child = dscm.id_ds_component_parent
             START WITH dscm.internal_name_child IN (i_root_name)
             ORDER SIBLINGS BY dscm.rank;
    
        r_ds_cmpt_mkt_rel ds_cmpt_mkt_rel%ROWTYPE;
        r_ds_def_event    ds_def_event%ROWTYPE;
        r_ds_event        ds_event%ROWTYPE;
    
        l_tbl_id_ds_event_target table_number := table_number();
        r_ds_event_target        ds_event_target%ROWTYPE;
    
        l_id_ds_cmpt_mkt_rel      ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        l_id_ds_cmpt_mkt_rel_next ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        l_id_ds_cmpt_mkt_rel_aux  ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        l_id_ds_cmpt_mkt_rel_dest ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        l_id_ds_def_event         ds_def_event.id_def_event%TYPE;
        l_id_ds_event             ds_event.id_ds_event%TYPE;
        l_id_ds_event_target      ds_event_target.id_ds_event_target%TYPE;
        l_id_ds_event_dest        ds_event.id_ds_event%TYPE;
    
        l_tbl_ds_def_event table_number;
        l_tbl_ds_event     table_number;
    
        l_service_params     ds_cmpt_mkt_rel.service_params%TYPE;
        l_service_params_aux ds_cmpt_mkt_rel.service_params%TYPE;
        l_tbl_service_params table_number;
    
        --l_tbl_event_target_to_process table_number := table_number();
    
        FUNCTION get_id_ds_cmpt_mkt_rel
        (
            i_id          IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_market_dest IN market.id_market%TYPE
        ) RETURN NUMBER IS
            l_id_comp_parent ds_cmpt_mkt_rel.id_ds_component_parent%TYPE;
            l_id_comp_child  ds_cmpt_mkt_rel.id_ds_component_child%TYPE;
        
            l_id_ds_cmpt_mkt_rel ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        BEGIN
        
            SELECT d.id_ds_component_parent, d.id_ds_component_child
              INTO l_id_comp_parent, l_id_comp_child
              FROM ds_cmpt_mkt_rel d
             WHERE d.id_ds_cmpt_mkt_rel = i_id;
        
            SELECT d.id_ds_cmpt_mkt_rel
              INTO l_id_ds_cmpt_mkt_rel
              FROM ds_cmpt_mkt_rel d
             WHERE d.id_ds_component_parent = l_id_comp_parent
               AND d.id_ds_component_child = l_id_comp_child
               AND d.id_market = i_market_dest;
        
            RETURN l_id_ds_cmpt_mkt_rel;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_id_ds_cmpt_mkt_rel;
    
    BEGIN
        OPEN c_ds_cmpt_mkt_rel(i_root, i_market_origin, i_market_dest);
        LOOP
            FETCH c_ds_cmpt_mkt_rel
                INTO l_id_ds_cmpt_mkt_rel;
            EXIT WHEN c_ds_cmpt_mkt_rel%NOTFOUND;
        
            SELECT *
              INTO r_ds_cmpt_mkt_rel
              FROM ds_cmpt_mkt_rel d
             WHERE d.id_ds_cmpt_mkt_rel = l_id_ds_cmpt_mkt_rel;
        
            l_id_ds_cmpt_mkt_rel_next := seq_ds_cmpt_mkt_rel.nextval;
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
                     internal_sample_text_type)
                VALUES
                    (l_id_ds_cmpt_mkt_rel_next,
                     i_market_dest,
                     r_ds_cmpt_mkt_rel.id_ds_component_parent,
                     r_ds_cmpt_mkt_rel.internal_name_parent,
                     r_ds_cmpt_mkt_rel.flg_component_type_parent,
                     r_ds_cmpt_mkt_rel.id_ds_component_child,
                     r_ds_cmpt_mkt_rel.internal_name_child,
                     r_ds_cmpt_mkt_rel.flg_component_type_child,
                     r_ds_cmpt_mkt_rel.rank,
                     r_ds_cmpt_mkt_rel.id_software,
                     r_ds_cmpt_mkt_rel.gender,
                     r_ds_cmpt_mkt_rel.age_min_value,
                     r_ds_cmpt_mkt_rel.age_min_unit_measure,
                     r_ds_cmpt_mkt_rel.age_max_value,
                     r_ds_cmpt_mkt_rel.age_max_unit_measure,
                     r_ds_cmpt_mkt_rel.id_unit_measure,
                     r_ds_cmpt_mkt_rel.id_unit_measure_subtype,
                     r_ds_cmpt_mkt_rel.max_len,
                     r_ds_cmpt_mkt_rel.min_value,
                     r_ds_cmpt_mkt_rel.max_value,
                     r_ds_cmpt_mkt_rel.flg_def_event_type,
                     r_ds_cmpt_mkt_rel.id_profile_template,
                     r_ds_cmpt_mkt_rel.position,
                     r_ds_cmpt_mkt_rel.flg_configurable,
                     r_ds_cmpt_mkt_rel.slg_internal_name,
                     r_ds_cmpt_mkt_rel.multi_option_column,
                     r_ds_cmpt_mkt_rel.code_domain,
                     r_ds_cmpt_mkt_rel.service_name,
                     r_ds_cmpt_mkt_rel.id_category,
                     r_ds_cmpt_mkt_rel.min_len,
                     r_ds_cmpt_mkt_rel.ds_alias,
                     r_ds_cmpt_mkt_rel.code_alt_desc,
                     r_ds_cmpt_mkt_rel.service_params,
                     r_ds_cmpt_mkt_rel.flg_exp_type,
                     r_ds_cmpt_mkt_rel.input_expression,
                     r_ds_cmpt_mkt_rel.input_mask,
                     r_ds_cmpt_mkt_rel.desc_function,
                     r_ds_cmpt_mkt_rel.comp_size,
                     r_ds_cmpt_mkt_rel.comp_offset,
                     r_ds_cmpt_mkt_rel.flg_hidden,
                     r_ds_cmpt_mkt_rel.flg_clearable,
                     r_ds_cmpt_mkt_rel.code_validation_message,
                     r_ds_cmpt_mkt_rel.flg_label_visible,
                     r_ds_cmpt_mkt_rel.internal_sample_text_type);
            EXCEPTION
                WHEN dup_val_on_index THEN
                    --Nunca deverá entrar aqui.
                    dbms_output.put_line('Record ' || l_id_ds_cmpt_mkt_rel ||
                                         ' for table ds_cmpt_mkt_rel already exists for market ' || i_market_dest || '.');
            END;
        
            --DEFAULT VALUES
            SELECT dde.id_def_event
              BULK COLLECT
              INTO l_tbl_ds_def_event
              FROM ds_def_event dde
             WHERE dde.id_ds_cmpt_mkt_rel = r_ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel;
        
            --Seria suposto só haver um evento default por elemento,
            --mas existem vários na bd com múltiplos eventos default
            IF l_tbl_ds_def_event.count > 0
            THEN
                FOR i IN l_tbl_ds_def_event.first .. l_tbl_ds_def_event.last
                LOOP
                    SELECT dde.*
                      INTO r_ds_def_event
                      FROM ds_def_event dde
                     WHERE dde.id_def_event = l_tbl_ds_def_event(i);
                
                    l_id_ds_def_event := seq_ds_def_event.nextval;
                
                    INSERT INTO ds_def_event
                        (id_def_event, id_ds_cmpt_mkt_rel, flg_event_type, id_action, flg_default)
                    VALUES
                        (l_id_ds_def_event,
                         l_id_ds_cmpt_mkt_rel_next,
                         r_ds_def_event.flg_event_type,
                         r_ds_def_event.id_action,
                         r_ds_def_event.flg_default);
                END LOOP;
            END IF;
        
            --Eventos
            SELECT de.id_ds_event
              BULK COLLECT
              INTO l_tbl_ds_event
              FROM ds_event de
             WHERE de.id_ds_cmpt_mkt_rel = r_ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel;
        
            IF l_tbl_ds_event.count > 0
            THEN
                FOR i IN l_tbl_ds_event.first .. l_tbl_ds_event.last
                LOOP
                
                    l_id_ds_event := seq_ds_event.nextval;
                
                    SELECT de.*
                      INTO r_ds_event
                      FROM ds_event de
                     WHERE de.id_ds_event = l_tbl_ds_event(i);
                
                    INSERT INTO ds_event
                        (id_ds_event, id_ds_cmpt_mkt_rel, VALUE, flg_type, id_action)
                    VALUES
                        (l_id_ds_event,
                         l_id_ds_cmpt_mkt_rel_next,
                         r_ds_event.value,
                         r_ds_event.flg_type,
                         r_ds_event.id_action);
                END LOOP;
            END IF;
        END LOOP;
        CLOSE c_ds_cmpt_mkt_rel;
    
        OPEN c_ds_event(i_root, i_market_origin);
        LOOP
            FETCH c_ds_event
                INTO l_id_ds_cmpt_mkt_rel;
            EXIT WHEN c_ds_event%NOTFOUND;
        
            SELECT *
              INTO r_ds_cmpt_mkt_rel
              FROM ds_cmpt_mkt_rel d
             WHERE d.id_ds_cmpt_mkt_rel = l_id_ds_cmpt_mkt_rel;
        
            SELECT de.id_ds_event
              BULK COLLECT
              INTO l_tbl_ds_event
              FROM ds_event de
             WHERE de.id_ds_cmpt_mkt_rel = r_ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel;
        
            IF l_tbl_ds_event.count > 0
            THEN
                FOR i IN l_tbl_ds_event.first .. l_tbl_ds_event.last
                LOOP
                    --Evento original
                    SELECT de.*
                      INTO r_ds_event
                      FROM ds_event de
                     WHERE de.id_ds_event = l_tbl_ds_event(i);
                
                    --Obter o id_ds_cmpt_mkt_rel do mercado de destino correspondente ao configurado 
                    --no ds_event do evento original
                    l_id_ds_cmpt_mkt_rel_aux := get_id_ds_cmpt_mkt_rel(r_ds_event.id_ds_cmpt_mkt_rel, i_market_dest);
                
                    --Obter o novo id de evento, equivalente o id de evento original
                    SELECT d.id_ds_event
                      INTO l_id_ds_event
                      FROM ds_event d
                     WHERE d.id_ds_cmpt_mkt_rel = l_id_ds_cmpt_mkt_rel_aux
                       AND (d.value = r_ds_event.value OR (d.value IS NULL AND r_ds_event.value IS NULL))
                       AND d.flg_type = r_ds_event.flg_type
                       AND (d.id_action = r_ds_event.id_action OR
                           (d.id_action IS NULL AND r_ds_event.id_action IS NULL));
                
                    --Para este evento, obter os seus targets
                    SELECT de.id_ds_event_target
                      BULK COLLECT
                      INTO l_tbl_id_ds_event_target
                      FROM ds_event_target de
                     WHERE de.id_ds_event = l_tbl_ds_event(i);
                
                    IF l_tbl_id_ds_event_target.count > 0
                    THEN
                        FOR j IN l_tbl_id_ds_event_target.first .. l_tbl_id_ds_event_target.last
                        LOOP
                            BEGIN
                                SELECT de.*
                                  INTO r_ds_event_target
                                  FROM ds_event_target de
                                 WHERE de.id_ds_event_target = l_tbl_id_ds_event_target(j);
                            
                                l_id_ds_event_target      := seq_ds_event_target.nextval;
                                l_id_ds_cmpt_mkt_rel_dest := get_id_ds_cmpt_mkt_rel(r_ds_event_target.id_ds_cmpt_mkt_rel,
                                                                                    i_market_dest);
                            
                                INSERT INTO ds_event_target
                                    (id_ds_event_target, id_ds_event, id_ds_cmpt_mkt_rel, flg_event_type, field_mask)
                                VALUES
                                    (l_id_ds_event_target,
                                     l_id_ds_event,
                                     l_id_ds_cmpt_mkt_rel_dest,
                                     r_ds_event_target.flg_event_type,
                                     r_ds_event_target.field_mask);
                            EXCEPTION
                                WHEN OTHERS THEN
                                    CONTINUE;
                            END;
                        END LOOP;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
        CLOSE c_ds_event;
    
        --Service params configurados na ds_cmpt_mkt_rel
        --Estes params podem ser configurados com pipe (ex: 123|456|789)
        OPEN c_ds_cmpt_mkt_rel_service(i_root, i_market_dest);
        LOOP
            --Obter os id_ds_cmpt_mkt_rel do mercado de destino que têm service params configurados
            --Obtém também o campo de service_params, mas estes ainda têm os ids originais que terão que ser convertidos
            FETCH c_ds_cmpt_mkt_rel_service
                INTO l_id_ds_cmpt_mkt_rel, l_service_params;
            EXIT WHEN c_ds_cmpt_mkt_rel_service%NOTFOUND;
        
            l_tbl_service_params := pk_utils.str_split_n(i_list => l_service_params, i_delim => '|');
        
            l_service_params_aux := NULL;
        
            FOR i IN l_tbl_service_params.first .. l_tbl_service_params.last
            LOOP
                l_id_ds_cmpt_mkt_rel_aux := get_id_ds_cmpt_mkt_rel(l_tbl_service_params(i), i_market_dest);
            
                IF i = 1
                THEN
                    l_service_params_aux := l_id_ds_cmpt_mkt_rel_aux;
                ELSE
                    l_service_params_aux := l_service_params_aux || '|' || l_id_ds_cmpt_mkt_rel_aux;
                END IF;
            
            END LOOP;
        
            UPDATE ds_cmpt_mkt_rel d
               SET d.service_params = l_service_params_aux
             WHERE d.id_ds_cmpt_mkt_rel = l_id_ds_cmpt_mkt_rel;
        END LOOP;
        CLOSE c_ds_cmpt_mkt_rel_service;
    END migrate_dynamic_screens;

    PROCEDURE get_form_scripts
    (
        i_root         IN table_varchar,
        i_market       IN market.id_market%TYPE DEFAULT NULL,
        i_software     IN software.id_software%TYPE DEFAULT NULL,
        i_force_update IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) IS
    
        CURSOR c_records IS
            SELECT id_ds_cmpt_mkt_rel, dscm.id_ds_component_parent, dscm.id_ds_component_child
              FROM ds_component dscp
              JOIN (SELECT d.id_ds_cmpt_mkt_rel,
                           d.id_market,
                           d.id_ds_component_parent,
                           d.internal_name_parent,
                           d.flg_component_type_parent,
                           d.id_ds_component_child,
                           d.internal_name_child,
                           d.flg_component_type_child,
                           d.rank,
                           d.flg_def_event_type
                      FROM ds_cmpt_mkt_rel d
                     WHERE (d.id_market = i_market OR i_market IS NULL)
                       AND (d.id_software = i_software OR i_software IS NULL)) dscm
                ON dscp.id_ds_component = dscm.id_ds_component_child
            CONNECT BY PRIOR dscm.id_ds_component_child = dscm.id_ds_component_parent
             START WITH dscm.internal_name_child IN (SELECT *
                                                       FROM TABLE(i_root))
             ORDER SIBLINGS BY dscm.rank;
    
        CURSOR c_ds_component(i_ds_component IN table_number) IS
            SELECT DISTINCT d.id_ds_component,
                            d.internal_name,
                            d.flg_component_type,
                            d.code_ds_component,
                            d.flg_data_type,
                            d.slg_internal_name,
                            d.max_len,
                            d.min_value,
                            d.max_value,
                            d.gender,
                            d.age_min_value,
                            d.age_min_unit_measure,
                            d.age_max_value,
                            d.age_max_unit_measure,
                            d.id_unit_measure,
                            d.id_unit_measure_subtype,
                            d.multi_option_column,
                            d.code_domain,
                            d.service_name,
                            d.internal_sample_text_type,
                            d.flg_wrap_text,
                            d.flg_repeatable
              FROM ds_component d
             WHERE d.id_ds_component IN (SELECT *
                                           FROM TABLE(i_ds_component));
    
        CURSOR c_ds_cmpt_mkt_rel(i_id_ds_cmpt_mkt_rel IN table_number) IS
            SELECT DISTINCT d.id_ds_cmpt_mkt_rel,
                            d.id_market,
                            d.id_ds_component_parent,
                            d.internal_name_parent,
                            d.flg_component_type_parent,
                            d.id_ds_component_child,
                            d.internal_name_child,
                            d.flg_component_type_child,
                            d.rank,
                            d.id_software,
                            d.gender,
                            d.age_min_value,
                            d.age_min_unit_measure,
                            d.age_max_value,
                            d.age_max_unit_measure,
                            d.id_unit_measure,
                            d.id_unit_measure_subtype,
                            d.max_len,
                            d.min_value,
                            d.max_value,
                            d.flg_def_event_type,
                            d.id_profile_template,
                            d.position,
                            d.flg_configurable,
                            d.slg_internal_name,
                            d.multi_option_column,
                            d.code_domain,
                            d.service_name,
                            d.id_category,
                            d.min_len,
                            d.ds_alias,
                            d.code_alt_desc,
                            d.service_params,
                            d.flg_exp_type,
                            d.input_expression,
                            d.input_mask,
                            d.desc_function,
                            d.comp_size,
                            d.comp_offset,
                            d.flg_hidden,
                            d.flg_clearable,
                            d.code_validation_message,
                            d.flg_label_visible,
                            d.internal_sample_text_type,
                            d.flg_data_type2,
                            d.text_line_nr
              FROM ds_cmpt_mkt_rel d
             WHERE d.id_ds_cmpt_mkt_rel IN (SELECT *
                                              FROM TABLE(i_id_ds_cmpt_mkt_rel));
    
        CURSOR c_ds_def_event(i_id_ds_cmpt_mkt_rel IN table_number) IS
            SELECT DISTINCT d.id_def_event, d.id_ds_cmpt_mkt_rel, d.flg_event_type, d.id_action, d.flg_default
              FROM ds_def_event d
             WHERE d.id_ds_cmpt_mkt_rel IN (SELECT *
                                              FROM TABLE(i_id_ds_cmpt_mkt_rel));
    
        CURSOR c_ds_event(i_id_ds_cmpt_mkt_rel IN table_number) IS
            SELECT DISTINCT d.id_ds_event, d.id_ds_cmpt_mkt_rel, d.value, d.flg_type, d.id_action
              FROM ds_event d
             WHERE d.id_ds_cmpt_mkt_rel IN (SELECT *
                                              FROM TABLE(i_id_ds_cmpt_mkt_rel));
    
        CURSOR c_ds_event_target(i_id_ds_cmpt_mkt_rel IN table_number) IS
            SELECT DISTINCT d.id_ds_event_target, d.id_ds_event, d.id_ds_cmpt_mkt_rel, d.flg_event_type, d.field_mask
              FROM ds_event_target d
             WHERE d.id_ds_cmpt_mkt_rel IN (SELECT *
                                              FROM TABLE(i_id_ds_cmpt_mkt_rel));
    
        r_ds_component    c_ds_component%ROWTYPE;
        r_ds_cmpt_mkt_rel c_ds_cmpt_mkt_rel%ROWTYPE;
        r_ds_def_event    c_ds_def_event%ROWTYPE;
        r_ds_event        c_ds_event%ROWTYPE;
        r_ds_event_target c_ds_event_target%ROWTYPE;
    
        l_tbl_id_ds_cmpt_mkt_rel table_number;
    
        l_tbl_id_ds_component_parent table_number;
        l_tbl_id_ds_component_child  table_number;
    
        l_tbl_id_ds_component   table_number;
        l_tbl_code_ds_component table_varchar;
    
        l_tbl_aliases table_varchar := table_varchar();
    
        l_message_desc      sys_message.desc_message%TYPE;
        l_alias_desc        sys_message.desc_message%TYPE;
        l_tag_generated     VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_translation_found VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
    BEGIN
        OPEN c_records;
        FETCH c_records BULK COLLECT
            INTO l_tbl_id_ds_cmpt_mkt_rel, l_tbl_id_ds_component_parent, l_tbl_id_ds_component_child;
        CLOSE c_records;
    
        SELECT DISTINCT d.id_ds_component, d.code_ds_component
          BULK COLLECT
          INTO l_tbl_id_ds_component, l_tbl_code_ds_component
          FROM ds_component d
         WHERE d.id_ds_component IN (SELECT *
                                       FROM TABLE(l_tbl_id_ds_component_parent))
            OR d.id_ds_component IN (SELECT *
                                       FROM TABLE(l_tbl_id_ds_component_child));
    
        dbms_output.put_line('-->ds_component|alert|dml');
        OPEN c_ds_component(l_tbl_id_ds_component);
        LOOP
            FETCH c_ds_component
                INTO r_ds_component;
            EXIT WHEN c_ds_component%NOTFOUND;
        
            dbms_output.put_line('BEGIN');
            dbms_output.put_line('insert into ds_component (ID_DS_COMPONENT, INTERNAL_NAME, FLG_COMPONENT_TYPE, CODE_DS_COMPONENT, FLG_DATA_TYPE, SLG_INTERNAL_NAME, MAX_LEN, MIN_VALUE, MAX_VALUE, GENDER, AGE_MIN_VALUE, AGE_MIN_UNIT_MEASURE, AGE_MAX_VALUE, AGE_MAX_UNIT_MEASURE, ID_UNIT_MEASURE, ID_UNIT_MEASURE_SUBTYPE, MULTI_OPTION_COLUMN, CODE_DOMAIN, SERVICE_NAME, INTERNAL_SAMPLE_TEXT_TYPE, FLG_WRAP_TEXT, FLG_REPEATABLE)');
            dbms_output.put_line('values (' || r_ds_component.id_ds_component || ', ''' ||
                                 r_ds_component.internal_name || ''', ' || CASE r_ds_component.flg_component_type WHEN NULL THEN
                                 'null' ELSE '''' || r_ds_component.flg_component_type || '''' END || ', ' || CASE
                                 r_ds_component.code_ds_component WHEN NULL THEN 'null' ELSE
                                 '''' || r_ds_component.code_ds_component || '''' END || ', ' || CASE WHEN
                                 r_ds_component.flg_data_type IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.flg_data_type || '''' END || ', ' || CASE WHEN
                                 r_ds_component.slg_internal_name IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.slg_internal_name || '''' END || ', ' || CASE WHEN
                                 r_ds_component.max_len IS NULL THEN 'null' ELSE to_char(r_ds_component.max_len)
                                 END || ', ' || CASE WHEN r_ds_component.min_value IS NULL THEN 'null' ELSE
                                 to_char(r_ds_component.min_value) END || ', ' || CASE WHEN
                                 r_ds_component.max_value IS NULL THEN 'null' ELSE to_char(r_ds_component.max_value)
                                 END || ', ' || CASE WHEN r_ds_component.gender IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.gender || '''' END || ', ' || CASE WHEN
                                 r_ds_component.age_min_value IS NULL THEN 'null' ELSE
                                 to_char(r_ds_component.age_min_value) END || ', ' || CASE WHEN
                                 r_ds_component.age_min_unit_measure IS NULL THEN 'null' ELSE
                                 to_char(r_ds_component.age_min_unit_measure) END || ', ' || CASE WHEN
                                 r_ds_component.age_max_value IS NULL THEN 'null' ELSE
                                 to_char(r_ds_component.age_max_value) END || ', ' || CASE WHEN
                                 r_ds_component.age_max_unit_measure IS NULL THEN 'null' ELSE
                                 to_char(r_ds_component.age_max_unit_measure) END || ', ' || CASE WHEN
                                 r_ds_component.id_unit_measure IS NULL THEN 'null' ELSE
                                 to_char(r_ds_component.id_unit_measure) END || ', ' || CASE WHEN
                                 r_ds_component.id_unit_measure_subtype IS NULL THEN 'null' ELSE
                                 to_char(r_ds_component.id_unit_measure_subtype) END || ', ' || CASE WHEN
                                 r_ds_component.multi_option_column IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.multi_option_column || '''' END || ', ' || CASE WHEN
                                 r_ds_component.code_domain IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.code_domain || '''' END || ', ' || CASE WHEN
                                 r_ds_component.service_name IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.service_name || '''' END || ', ' || CASE WHEN
                                 r_ds_component.internal_sample_text_type IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.internal_sample_text_type || '''' END || ', ' || CASE WHEN
                                 r_ds_component.flg_wrap_text IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.flg_wrap_text || '''' END || ', ' || CASE WHEN
                                 r_ds_component.flg_repeatable IS NULL THEN 'null' ELSE
                                 '''' || r_ds_component.flg_repeatable || '''' END || ');');
        
            dbms_output.put_line('EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN  DBMS_OUTPUT.put_line(''Duplicated record!'');');
            IF i_force_update = pk_alert_constant.g_yes
            THEN
                dbms_output.put_line('UPDATE ds_component d
   SET d.flg_data_type             = ' || CASE WHEN
                                     r_ds_component.flg_data_type IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.flg_data_type || ''''
                                     END || ', ' || '       d.slg_internal_name         = ' || CASE WHEN
                                     r_ds_component.slg_internal_name IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.slg_internal_name || ''''
                                     END || ', ' || '       d.max_len                   = ' || CASE WHEN
                                     r_ds_component.max_len IS NULL THEN 'null' ELSE to_char(r_ds_component.max_len)
                                     END || ', ' || '       d.min_value                 = ' || CASE WHEN
                                     r_ds_component.min_value IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.min_value)
                                     END || ', ' || '       d.max_value                 = ' || CASE WHEN
                                     r_ds_component.max_value IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.max_value)
                                     END || ', ' || '       d.gender                    = ' || CASE WHEN
                                     r_ds_component.gender IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.gender || ''''
                                     END || ', ' || '       d.age_min_value             = ' || CASE WHEN
                                     r_ds_component.age_min_value IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.age_min_value)
                                     END || ', ' || '       d.age_min_unit_measure      = ' || CASE WHEN
                                     r_ds_component.age_min_unit_measure IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.age_min_unit_measure)
                                     END || ', ' || '       d.age_max_value             = ' || CASE WHEN
                                     r_ds_component.age_max_value IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.age_max_value)
                                     END || ', ' || '       d.age_max_unit_measure      = ' || CASE WHEN
                                     r_ds_component.age_max_unit_measure IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.age_max_unit_measure)
                                     END || ', ' || '       d.id_unit_measure           = ' || CASE WHEN
                                     r_ds_component.id_unit_measure IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.id_unit_measure)
                                     END || ', ' || '       d.id_unit_measure_subtype   = ' || CASE WHEN
                                     r_ds_component.id_unit_measure_subtype IS NULL THEN 'null' ELSE
                                     to_char(r_ds_component.id_unit_measure_subtype)
                                     END || ', ' || '       d.multi_option_column       = ' || CASE WHEN
                                     r_ds_component.multi_option_column IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.multi_option_column || ''''
                                     END || ', ' || '       d.code_domain               = ' || CASE WHEN
                                     r_ds_component.code_domain IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.code_domain || ''''
                                     END || ', ' || '       d.service_name              = ' || CASE WHEN
                                     r_ds_component.service_name IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.service_name || ''''
                                     END || ', ' || '       d.internal_sample_text_type = ' || CASE WHEN
                                     r_ds_component.internal_sample_text_type IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.internal_sample_text_type || ''''
                                     END || ', ' || '       d.flg_wrap_text             = ' || CASE WHEN
                                     r_ds_component.flg_wrap_text IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.flg_wrap_text || ''''
                                     END || ', ' || '       d.flg_repeatable             = ' || CASE WHEN
                                     r_ds_component.flg_repeatable IS NULL THEN 'null' ELSE
                                     '''' || r_ds_component.flg_repeatable || ''''
                                     END || ' WHERE d.id_ds_component = ' || r_ds_component.id_ds_component || '; ');
            END IF;
            dbms_output.put_line('END;');
            dbms_output.put_line('/');
        
        END LOOP;
        CLOSE c_ds_component;
    
        dbms_output.put_line(chr(10));
        dbms_output.put_line('-->ds_cmpt_mkt_rel|alert|dml');
        OPEN c_ds_cmpt_mkt_rel(l_tbl_id_ds_cmpt_mkt_rel);
        LOOP
            FETCH c_ds_cmpt_mkt_rel
                INTO r_ds_cmpt_mkt_rel;
            EXIT WHEN c_ds_cmpt_mkt_rel%NOTFOUND;
        
            dbms_output.put_line('BEGIN');
            dbms_output.put_line('insert into ds_cmpt_mkt_rel (ID_DS_CMPT_MKT_REL, ID_MARKET, ID_DS_COMPONENT_PARENT, INTERNAL_NAME_PARENT, FLG_COMPONENT_TYPE_PARENT, ID_DS_COMPONENT_CHILD, INTERNAL_NAME_CHILD, FLG_COMPONENT_TYPE_CHILD, RANK, ID_SOFTWARE, GENDER, AGE_MIN_VALUE, AGE_MIN_UNIT_MEASURE, AGE_MAX_VALUE, AGE_MAX_UNIT_MEASURE, ID_UNIT_MEASURE, ID_UNIT_MEASURE_SUBTYPE, MAX_LEN, MIN_VALUE, MAX_VALUE, FLG_DEF_EVENT_TYPE, ID_PROFILE_TEMPLATE, POSITION, FLG_CONFIGURABLE, SLG_INTERNAL_NAME, MULTI_OPTION_COLUMN, CODE_DOMAIN, SERVICE_NAME, ID_CATEGORY, MIN_LEN, DS_ALIAS, CODE_ALT_DESC, SERVICE_PARAMS, FLG_EXP_TYPE, INPUT_EXPRESSION, INPUT_MASK, DESC_FUNCTION, COMP_SIZE, COMP_OFFSET, FLG_HIDDEN, FLG_CLEARABLE, CODE_VALIDATION_MESSAGE, FLG_LABEL_VISIBLE, INTERNAL_SAMPLE_TEXT_TYPE, FLG_DATA_TYPE2, TEXT_LINE_NR)');
            dbms_output.put_line('values( ' || r_ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel || ', ' ||
                                 r_ds_cmpt_mkt_rel.id_market || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.id_ds_component_parent IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.id_ds_component_parent) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.internal_name_parent IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.internal_name_parent || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_component_type_parent IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_component_type_parent || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.id_ds_component_child IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.id_ds_component_child) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.internal_name_child IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.internal_name_child || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_component_type_child IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_component_type_child || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.rank IS NULL THEN 'null' ELSE to_char(r_ds_cmpt_mkt_rel.rank)
                                 END || ', ' || CASE WHEN r_ds_cmpt_mkt_rel.id_software IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.id_software) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.gender IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.gender || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.age_min_value IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.age_min_value) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.age_min_unit_measure IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.age_min_unit_measure) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.age_max_value IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.age_max_value) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.age_max_unit_measure IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.age_max_unit_measure) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.id_unit_measure IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.id_unit_measure) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.id_unit_measure_subtype IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.id_unit_measure_subtype) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.max_len IS NULL THEN 'null' ELSE to_char(r_ds_cmpt_mkt_rel.max_len)
                                 END || ', ' || CASE WHEN r_ds_cmpt_mkt_rel.min_value IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.min_value) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.max_value IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.max_value) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_def_event_type IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_def_event_type || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.id_profile_template IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.id_profile_template) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.position IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.position) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_configurable IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_configurable || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.slg_internal_name IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.slg_internal_name || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.multi_option_column IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.multi_option_column || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.code_domain IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.code_domain || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.service_name IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.service_name || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.id_category IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.id_category) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.min_len IS NULL THEN 'null' ELSE to_char(r_ds_cmpt_mkt_rel.min_len)
                                 END || ', ' || CASE WHEN r_ds_cmpt_mkt_rel.ds_alias IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.ds_alias || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.code_alt_desc IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.code_alt_desc || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.service_params IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.service_params || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_exp_type IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_exp_type || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.input_expression IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.input_expression || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.input_mask IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.input_mask || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.desc_function IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.desc_function || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.comp_size IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.comp_size) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.comp_offset IS NULL THEN 'null' ELSE
                                 to_char(r_ds_cmpt_mkt_rel.comp_offset) END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_hidden IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_hidden || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_clearable IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_clearable || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.code_validation_message IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.code_validation_message || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_label_visible IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_label_visible || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.internal_sample_text_type IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.internal_sample_text_type || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.flg_data_type2 IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.flg_data_type2 || '''' END || ', ' || CASE WHEN
                                 r_ds_cmpt_mkt_rel.text_line_nr IS NULL THEN 'null' ELSE
                                 '''' || r_ds_cmpt_mkt_rel.text_line_nr || '''' END || '); ');
        
            dbms_output.put_line('EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN  DBMS_OUTPUT.put_line(''Duplicated record!'');');
            IF i_force_update = pk_alert_constant.g_yes
            THEN
                dbms_output.put_line('UPDATE ds_cmpt_mkt_rel d
set d.id_market = ' || CASE WHEN r_ds_cmpt_mkt_rel.id_market IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_market || ''''
                                     END || ', ' || '    d.id_ds_component_parent = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.id_ds_component_parent IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_ds_component_parent || ''''
                                     END || ', ' || '    d.internal_name_parent = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.internal_name_parent IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.internal_name_parent || ''''
                                     END || ', ' || '    d.flg_component_type_parent = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_component_type_parent IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_component_type_parent || ''''
                                     END || ', ' || '    d.id_ds_component_child = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.id_ds_component_child IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_ds_component_child || ''''
                                     END || ', ' || '    d.internal_name_child = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.internal_name_child IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.internal_name_child || ''''
                                     END || ', ' || '    d.flg_component_type_child = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_component_type_child IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_component_type_child || ''''
                                     END || ', ' || '    d.rank = ' || CASE WHEN r_ds_cmpt_mkt_rel.rank IS NULL THEN
                                     'null' ELSE '''' || r_ds_cmpt_mkt_rel.rank || ''''
                                     END || ', ' || '    d.id_software = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.id_software IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_software || ''''
                                     END || ', ' || '    d.gender = ' || CASE WHEN r_ds_cmpt_mkt_rel.gender IS NULL THEN
                                     'null' ELSE '''' || r_ds_cmpt_mkt_rel.gender || ''''
                                     END || ', ' || '    d.age_min_value = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.age_min_value IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.age_min_value || ''''
                                     END || ', ' || '    d.age_min_unit_measure = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.age_min_unit_measure IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.age_min_unit_measure || ''''
                                     END || ', ' || '    d.age_max_value = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.age_max_value IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.age_max_value || ''''
                                     END || ', ' || '    d.age_max_unit_measure = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.age_max_unit_measure IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.age_max_unit_measure || ''''
                                     END || ', ' || '    d.id_unit_measure = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.id_unit_measure IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_unit_measure || ''''
                                     END || ', ' || '    d.id_unit_measure_subtype = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.id_unit_measure_subtype IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_unit_measure_subtype || ''''
                                     END || ', ' || '    d.max_len = ' || CASE WHEN r_ds_cmpt_mkt_rel.max_len IS NULL THEN
                                     'null' ELSE '''' || r_ds_cmpt_mkt_rel.max_len || ''''
                                     END || ', ' || '    d.min_value = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.min_value IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.min_value || ''''
                                     END || ', ' || '    d.max_value = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.max_value IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.max_value || ''''
                                     END || ', ' || '    d.flg_def_event_type = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_def_event_type IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_def_event_type || ''''
                                     END || ', ' || '    d.id_profile_template = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.id_profile_template IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_profile_template || ''''
                                     END || ', ' || '    d.position = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.position IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.position || ''''
                                     END || ', ' || '    d.flg_configurable = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_configurable IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_configurable || ''''
                                     END || ', ' || '    d.slg_internal_name = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.slg_internal_name IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.slg_internal_name || ''''
                                     END || ', ' || '    d.multi_option_column = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.multi_option_column IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.multi_option_column || ''''
                                     END || ', ' || '    d.code_domain = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.code_domain IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.code_domain || ''''
                                     END || ', ' || '    d.service_name = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.service_name IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.service_name || ''''
                                     END || ', ' || '    d.id_category = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.id_category IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.id_category || ''''
                                     END || ', ' || '    d.min_len = ' || CASE WHEN r_ds_cmpt_mkt_rel.min_len IS NULL THEN
                                     'null' ELSE '''' || r_ds_cmpt_mkt_rel.min_len || ''''
                                     END || ', ' || '    d.ds_alias = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.ds_alias IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.ds_alias || ''''
                                     END || ', ' || '    d.code_alt_desc = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.code_alt_desc IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.code_alt_desc || ''''
                                     END || ', ' || '    d.service_params = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.service_params IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.service_params || ''''
                                     END || ', ' || '    d.flg_exp_type = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_exp_type IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_exp_type || ''''
                                     END || ', ' || '    d.input_expression = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.input_expression IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.input_expression || ''''
                                     END || ', ' || '    d.input_mask = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.input_mask IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.input_mask || ''''
                                     END || ', ' || '    d.desc_function = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.desc_function IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.desc_function || ''''
                                     END || ', ' || '    d.comp_size = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.comp_size IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.comp_size || ''''
                                     END || ', ' || '    d.comp_offset = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.comp_offset IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.comp_offset || ''''
                                     END || ', ' || '    d.flg_hidden = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_hidden IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_hidden || ''''
                                     END || ', ' || '    d.flg_clearable = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_clearable IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_clearable || ''''
                                     END || ', ' || '    d.code_validation_message = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.code_validation_message IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.code_validation_message || ''''
                                     END || ', ' || '    d.flg_label_visible = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_label_visible IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_label_visible || ''''
                                     END || ', ' || '    d.internal_sample_text_type = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.internal_sample_text_type IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.internal_sample_text_type || ''''
                                     END || ', ' || '    d.flg_data_type2  = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.flg_data_type2 IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.flg_data_type2 || ''''
                                     END || ', ' || '    d.text_line_nr  = ' || CASE WHEN
                                     r_ds_cmpt_mkt_rel.text_line_nr IS NULL THEN 'null' ELSE
                                     '''' || r_ds_cmpt_mkt_rel.text_line_nr || ''''
                                     END || ' WHERE d.id_ds_cmpt_mkt_rel = ' || r_ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel || ';');
            END IF;
            dbms_output.put_line('END;');
            dbms_output.put_line('/');
        
            IF r_ds_cmpt_mkt_rel.code_alt_desc IS NOT NULL
            THEN
                l_tbl_aliases.extend();
                l_tbl_aliases(l_tbl_aliases.count) := r_ds_cmpt_mkt_rel.code_alt_desc;
            END IF;
        END LOOP;
        CLOSE c_ds_cmpt_mkt_rel;
    
        dbms_output.put_line(chr(10));
        dbms_output.put_line('-->ds_def_event|alert|dml');
        OPEN c_ds_def_event(l_tbl_id_ds_cmpt_mkt_rel);
        LOOP
            FETCH c_ds_def_event
                INTO r_ds_def_event;
            EXIT WHEN c_ds_def_event%NOTFOUND;
        
            dbms_output.put_line('BEGIN');
            dbms_output.put_line('insert into ds_def_event (ID_DEF_EVENT, ID_DS_CMPT_MKT_REL, FLG_EVENT_TYPE, ID_ACTION, FLG_DEFAULT)');
            dbms_output.put_line('values (' || r_ds_def_event.id_def_event || ', ' ||
                                 r_ds_def_event.id_ds_cmpt_mkt_rel || ', ' || '''' || r_ds_def_event.flg_event_type ||
                                 ''', ' || CASE WHEN r_ds_def_event.id_action IS NULL THEN 'null' ELSE
                                 to_char(r_ds_def_event.id_action) END || ', ' || CASE WHEN
                                 r_ds_def_event.flg_default IS NULL THEN 'null' ELSE
                                 '''' || r_ds_def_event.flg_default || '''' END || ');');
            dbms_output.put_line('EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN  DBMS_OUTPUT.put_line(''Duplicated record!'');');
            IF i_force_update = pk_alert_constant.g_yes
            THEN
                dbms_output.put_line('UPDATE ds_def_event d
   SET d.id_ds_cmpt_mkt_rel = ' || CASE WHEN
                                     r_ds_def_event.id_ds_cmpt_mkt_rel IS NULL THEN 'null' ELSE
                                     '''' || r_ds_def_event.id_ds_cmpt_mkt_rel || ''''
                                     END || ', ' || '       d.flg_event_type = ' || CASE WHEN
                                     r_ds_def_event.flg_event_type IS NULL THEN 'null' ELSE
                                     '''' || r_ds_def_event.flg_event_type || ''''
                                     END || ', ' || '       d.id_action= ' || CASE WHEN
                                     r_ds_def_event.id_action IS NULL THEN 'null' ELSE
                                     '''' || r_ds_def_event.id_action || ''''
                                     END || ', ' || '       d.flg_default = ' || CASE WHEN
                                     r_ds_def_event.flg_default IS NULL THEN 'null' ELSE
                                     '''' || r_ds_def_event.flg_default || ''''
                                     END || ' WHERE d.id_def_event = ' || r_ds_def_event.id_def_event || ';');
            END IF;
            dbms_output.put_line('END;');
            dbms_output.put_line('/');
        END LOOP;
        CLOSE c_ds_def_event;
    
        dbms_output.put_line(chr(10));
        dbms_output.put_line('-->ds_event|alert|dml');
        OPEN c_ds_event(l_tbl_id_ds_cmpt_mkt_rel);
        LOOP
            FETCH c_ds_event
                INTO r_ds_event;
            EXIT WHEN c_ds_event%NOTFOUND;
        
            dbms_output.put_line('BEGIN');
            dbms_output.put_line('insert into ds_event (ID_DS_EVENT, ID_DS_CMPT_MKT_REL, VALUE, FLG_TYPE, ID_ACTION)');
            dbms_output.put_line('values (' || r_ds_event.id_ds_event || ', ' || r_ds_event.id_ds_cmpt_mkt_rel || ', ' ||
                                 
                                 CASE WHEN r_ds_event.value IS NULL THEN 'null' ELSE
                                 '''' || REPLACE(r_ds_event.value, '''', '''''') || '''' END || ', ' || CASE WHEN
                                 r_ds_event.flg_type IS NULL THEN 'null' ELSE '''' || r_ds_event.flg_type || ''''
                                 END || ', ' || CASE WHEN r_ds_event.id_action IS NULL THEN 'null' ELSE
                                 to_char(r_ds_event.id_action) END || ');');
            dbms_output.put_line('EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN  DBMS_OUTPUT.put_line(''Duplicated record!'');');
            IF i_force_update = pk_alert_constant.g_yes
            THEN
                dbms_output.put_line('UPDATE ds_event d
   SET d.id_ds_cmpt_mkt_rel = ' || CASE WHEN r_ds_event.id_ds_cmpt_mkt_rel IS NULL THEN
                                     'null' ELSE '''' || r_ds_event.id_ds_cmpt_mkt_rel || ''''
                                     END || ', ' || '       d.value = ' || CASE WHEN r_ds_event.value IS NULL THEN
                                     'null' ELSE '''' || REPLACE(r_ds_event.value, '''', '''''') || ''''
                                     END || ', ' || '       d.flg_type = ' || CASE WHEN r_ds_event.flg_type IS NULL THEN
                                     'null' ELSE '''' || r_ds_event.flg_type || ''''
                                     END || ', ' || '       d.id_action = ' || CASE WHEN r_ds_event.id_action IS NULL THEN
                                     'null' ELSE '''' || r_ds_event.id_action || ''''
                                     END || ' WHERE d.id_ds_event = ' || r_ds_event.id_ds_event || ';');
            END IF;
            dbms_output.put_line('END;');
            dbms_output.put_line('/');
        END LOOP;
        CLOSE c_ds_event;
    
        dbms_output.put_line(chr(10));
        dbms_output.put_line('-->ds_event_target|alert|dml');
        OPEN c_ds_event_target(l_tbl_id_ds_cmpt_mkt_rel);
        LOOP
            FETCH c_ds_event_target
                INTO r_ds_event_target;
            EXIT WHEN c_ds_event_target%NOTFOUND;
        
            dbms_output.put_line('BEGIN');
            dbms_output.put_line('insert into ds_event_target (ID_DS_EVENT_TARGET, ID_DS_EVENT, ID_DS_CMPT_MKT_REL, FLG_EVENT_TYPE, FIELD_MASK)');
            dbms_output.put_line('values (' || r_ds_event_target.id_ds_event_target || ', ' ||
                                 r_ds_event_target.id_ds_event || ', ' || r_ds_event_target.id_ds_cmpt_mkt_rel || ', ' || CASE WHEN
                                 r_ds_event_target.flg_event_type IS NULL THEN 'null' ELSE
                                 '''' || r_ds_event_target.flg_event_type || '''' END || ', ' || CASE WHEN
                                 r_ds_event_target.field_mask IS NULL THEN 'null' ELSE
                                 '''' || r_ds_event_target.field_mask || '''' END || '); ');
            dbms_output.put_line('EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN  DBMS_OUTPUT.put_line(''Duplicated record!'');');
        
            IF i_force_update = pk_alert_constant.g_yes
            THEN
                dbms_output.put_line('update ds_event_target d
set d.id_ds_event = ' || CASE WHEN r_ds_event_target.id_ds_event IS NULL THEN
                                     'null' ELSE '''' || r_ds_event_target.id_ds_event || ''''
                                     END || ', ' || '    d.id_ds_cmpt_mkt_rel = ' || CASE WHEN
                                     r_ds_event_target.id_ds_cmpt_mkt_rel IS NULL THEN 'null' ELSE
                                     '''' || r_ds_event_target.id_ds_cmpt_mkt_rel || ''''
                                     END || ', ' || '    d.flg_event_type = ' || CASE WHEN
                                     r_ds_event_target.flg_event_type IS NULL THEN 'null' ELSE
                                     '''' || r_ds_event_target.flg_event_type || ''''
                                     END || ', ' || '    d.field_mask = ' || CASE WHEN
                                     r_ds_event_target.field_mask IS NULL THEN 'null' ELSE
                                     '''' || r_ds_event_target.field_mask || ''''
                                     END || ' where d.id_ds_event_target = ' || r_ds_event_target.id_ds_event_target || ';');
            END IF;
        
            dbms_output.put_line('END;');
            dbms_output.put_line('/');
        END LOOP;
        CLOSE c_ds_event_target;
    
        FOR i IN 1 .. 22
        LOOP
            l_tag_generated     := pk_alert_constant.g_no;
            l_translation_found := pk_alert_constant.g_no;
        
            FOR j IN l_tbl_code_ds_component.first .. l_tbl_code_ds_component.last
            LOOP
                l_message_desc := pk_message.get_message(i, l_tbl_code_ds_component(j));
            
                IF l_message_desc IS NOT NULL
                THEN
                    IF l_tag_generated = pk_alert_constant.g_no
                    THEN
                        IF i IN (13, 20)
                        THEN
                            dbms_output.put_line('-->sys_message_' || i || '_utf8|alert|utf8');
                        ELSE
                            dbms_output.put_line('-->sys_message_' || i || '|alert|dml');
                        END IF;
                    
                        dbms_output.put_line('BEGIN');
                        l_tag_generated     := pk_alert_constant.g_yes;
                        l_translation_found := pk_alert_constant.g_yes;
                    END IF;
                
                    dbms_output.put_line('pk_message.insert_into_sys_message(' || i || ', ''' ||
                                         l_tbl_code_ds_component(j) || ''', ''' ||
                                         REPLACE(l_message_desc, '''', '''''') || ''');');
                END IF;
            END LOOP;
        
            FOR j IN l_tbl_aliases.first .. l_tbl_aliases.last
            LOOP
                l_alias_desc := pk_message.get_message(i, l_tbl_aliases(j));
            
                IF l_alias_desc IS NOT NULL
                THEN
                    IF l_tag_generated = pk_alert_constant.g_no
                    THEN
                        IF i IN (13, 20)
                        THEN
                            dbms_output.put_line('-->sys_message_' || i || '_utf8|alert|utf8');
                        ELSE
                            dbms_output.put_line('-->sys_message_' || i || '|alert|dml');
                        END IF;
                    
                        dbms_output.put_line('BEGIN');
                        l_tag_generated     := pk_alert_constant.g_yes;
                        l_translation_found := pk_alert_constant.g_yes;
                    END IF;
                
                    dbms_output.put_line('pk_message.insert_into_sys_message(' || i || ', ''' || l_tbl_aliases(j) ||
                                         ''', ''' || REPLACE(l_alias_desc, '''', '''''') || ''');');
                END IF;
            END LOOP;
        
            IF l_translation_found = pk_alert_constant.g_yes
            THEN
                dbms_output.put_line('END;');
                dbms_output.put_line('/');
            END IF;
        END LOOP;
    
    END get_form_scripts;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_orders_utils;
/
