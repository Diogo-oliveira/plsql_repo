CREATE OR REPLACE VIEW V_DEATH_FETALS_RAW AS 
SELECT id_death_registry, internal_name, id_ds_component, xvalue
  FROM (SELECT id_death_registry, internal_name, id_ds_component, xvalue
          FROM (
                -- xtransform
                SELECT id_death_registry,
                        internal_name,
                        id_ds_component,
                        CASE
                             WHEN value_n IS NOT NULL THEN
                              to_char(value_n)
                             WHEN value_tz IS NOT NULL THEN
                              value_tz
                             WHEN value_vc2 IS NOT NULL THEN
                              value_vc2
                             ELSE
                              ''
                         END xvalue
                  FROM (SELECT id_lang,
                                id_death_registry,
                                internal_name,
                                id_ds_component,
                                'N' k_type_number,
                                'D' k_type_timestamp,
                                'V' k_type_varchar,
                                slg_internal_name,
                                multi_option_column,
                                pk_death_registry.get_datatype(i_id_ds_comp => id_ds_component) comp_datatype,
                                CASE
                                     WHEN value_tz IS NOT NULL THEN
                                      pk_date_utils.date_send_tsz(i_lang => id_lang,
                                                                  i_date => value_tz,
                                                                  i_inst => id_institution,
                                                                  i_soft => 0)
                                     ELSE
                                      NULL
                                 END value_tz,
                                value_vc2,
                                to_char(value_n) value_n
                           FROM (SELECT
                                 -- DEATH_REGISTRY
                                  17 id_lang,
                                  dfetal.id_death_registry
                                  -- DEATH_REGISTRY_DET
                                 ,
                                  drd.id_ds_component,
                                  drd.value_tz        value_tz
                                  -- DS_COMPONENT
                                 ,
                                  ds.internal_name,
                                  ds.code_ds_component,
                                  ds.flg_data_type,
                                  ds.flg_component_type,
                                  ds.slg_internal_name,
                                  ds.multi_option_column
                                  -- visit
                                 ,
                                  vis.id_institution,
                                  CASE
                                       WHEN ds.slg_internal_name IS NOT NULL THEN
                                        pk_sys_list.get_sys_list_context(i_internal_name => ds.slg_internal_name,
                                                                         i_sys_list      => drd.value_n)
                                       WHEN ds.multi_option_column IS NOT NULL THEN
                                        pk_multichoice.get_id_content(i_multichoice_option => drd.value_n)
                                       WHEN ds.flg_data_type IN ('ME', 'MP', 'ML', 'MJ') THEN
                                        pk_adt.get_rb_reg_classifier_code(i_rb_reg_class => drd.value_n)
                                       ELSE
                                        drd.value_vc2
                                   END value_vc2,
                                  CASE
                                       WHEN ds.slg_internal_name IS NOT NULL THEN
                                        NULL
                                       WHEN ds.multi_option_column IS NOT NULL THEN
                                        NULL
                                       WHEN ds.flg_data_type IN ('ME', 'MP', 'ML') THEN
                                        NULL
                                       ELSE
                                        drd.value_n
                                   END value_n
                                   FROM death_registry_det drd
                                   JOIN death_registry dfetal
                                     ON drd.id_death_registry = dfetal.id_death_registry
                                   JOIN ds_component ds
                                     ON ds.id_ds_component = drd.id_ds_component
                                   JOIN episode epis
                                     ON epis.id_episode = dfetal.id_episode
                                   JOIN visit vis
                                     ON vis.id_visit = epis.id_visit
                                   JOIN v_death_fet_comp_aux v_list
                                     ON v_list.id_ds_component = ds.id_ds_component
                                  WHERE 0 = 0
                                    AND dfetal.flg_type = 'F'
                                    AND dfetal.flg_status = 'A') xsql) xtransform)
        UNION ALL
        SELECT -1, ds.internal_name, ds.id_ds_component, NULL xvalue
          FROM v_death_fet_comp_aux v_list
          JOIN ds_component ds
            ON v_list.id_ds_component = ds.id_ds_component
         WHERE ds.id_ds_component NOT IN (SELECT DISTINCT id_ds_component
                                            FROM death_registry_det drd
                                            JOIN death_registry dr
                                              ON drd.id_death_registry = dr.id_death_registry
                                           WHERE dr.flg_status = 'A'
                                             AND dr.flg_type = 'F')) xmain
;
