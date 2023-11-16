CREATE OR REPLACE VIEW V_DEATH_PATIENT_RAW AS
SELECT id_death_registry, internal_name, id_ds_component, xvalue
  FROM (SELECT id_death_registry, internal_name, id_ds_component, xvalue
          FROM (
                -- xtransform
                SELECT id_death_registry,
                        internal_name,
                        id_ds_component,
                        decode(comp_datatype,
                               k_type_number,
                               nvl(value_vc2, value_n),
                               k_type_timestamp,
                               value_tz,
                               k_type_varchar,
                               value_vc2) xvalue
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
                                         CASE
                                         WHEN flg_data_type = 'DP' THEN
                                           pk_dynamic_screen.process_mx_partial_dt
                                                (
                                                i_lang      => 17,
                                                i_prof      => profissional(NULL, id_institution, 0),
                                                i_dt_exists => 'Y',
                                                i_value     => value_tz,
                                                i_dt_format => value_vc2
                                                )
                                          ELSE
                                              pk_date_utils.date_send_tsz(i_lang => 17,
                                                                          i_date => value_tz,
                                                                          i_inst => id_institution,
                                                                          i_soft => 0)
                                          END
                               ELSE
                                      NULL
                               END value_tz,
                                value_vc2,
                                to_char(value_n) value_n
                           FROM (SELECT
                                 -- DEATH_REGISTRY
                                  17 id_lang,
                                  dr.id_death_registry,
                                  -- DEATH_REGISTRY_DET
                                  drd.id_ds_component,
                                  drd.value_tz        value_tz,
                                  -- DS_COMPONENT
                                  ds.internal_name,
                                  ds.code_ds_component,
                                  ds.flg_data_type,
                                  ds.flg_component_type,
                                  ds.slg_internal_name,
                                  ds.multi_option_column,
                                  -- visit
                                  vis.id_institution,
                                  CASE
                                       WHEN ds.slg_internal_name IS NOT NULL THEN
                                        pk_sys_list.get_sys_list_context(i_internal_name => ds.slg_internal_name,
                                                                         i_sys_list      => drd.value_n)
                                       WHEN ds.multi_option_column IS NOT NULL THEN
                                        pk_multichoice.get_id_content(i_multichoice_option => drd.value_n)
                                       WHEN ds.flg_data_type IN ('ME', 'MP', 'ML') THEN
                                        pk_adt.get_rb_reg_classifier_code(i_rb_reg_class => drd.value_n)
                                       when ds.flg_data_type = 'MJ' then
                                         pk_adt.get_rb_reg_classifier_code(i_rb_reg_class =>pk_adt.get_jurisdiction_id(drd.value_n))
                                       WHEN ds.flg_data_type = 'K' THEN
                                        drd.value_n || '|' ||
                                        (SELECT id_content
                                           FROM unit_measure um
                                          WHERE um.id_unit_measure = drd.unit_measure_value)
                                       ELSE
                                        drd.value_vc2
                                   END value_vc2,
                                  CASE
                                       WHEN ds.slg_internal_name IS NOT NULL THEN
                                        NULL
                                       WHEN ds.multi_option_column IS NOT NULL THEN
                                        NULL
                                       WHEN ds.flg_data_type IN ('ME', 'MP', 'ML', 'MJ') THEN
                                        NULL
                                       WHEN ds.flg_data_type = 'K' THEN
                                        NULL
                                       ELSE
                                        drd.value_n
                                   END value_n
                                   FROM death_registry_det drd
                                   JOIN death_registry dr
                                     ON drd.id_death_registry = dr.id_death_registry
                                   JOIN ds_component ds
                                     ON ds.id_ds_component = drd.id_ds_component
                                   JOIN episode epis
                                     ON epis.id_episode = dr.id_episode
                                   JOIN visit vis
                                     ON vis.id_visit = epis.id_visit
                                   LEFT JOIN v_death_pat_comp_aux v_list
                                     ON ds.id_ds_component = v_list.id_ds_component
                                  WHERE 0 = 0
                                    AND dr.flg_type = 'P'
                                    AND dr.flg_status = 'A') xsql) xtransform)
        --ORDER BY id_Death_registry, ds_component_desc
        UNION ALL
        SELECT dc.id_death_registry,
               'CAUSE_' || to_char(dc.death_cause_rank) internal_name,
               dc.death_cause_rank id_ds_component,
               pk_diagnosis_core.get_diagnosis_code(i_diagnosis   => decode(ed.id_diagnosis,-1,dc.id_diagnosis, ed.id_diagnosis),
                                                    i_institution => e.id_institution,
                                                    i_software    => pk_episode.get_episode_software(i_lang       => 17,
                                                                                                     i_prof       => profissional(NULL,
                                                                                                                                  e.id_institution,
                                                                                                                                  0),
                                                                                                     i_id_episode => e.id_episode))  xvalue
          FROM death_cause dc
          JOIN death_registry dr
            ON dr.id_death_registry = dc.id_death_registry
          left JOIN epis_diagnosis ed
            ON ed.id_epis_diagnosis = dc.id_epis_diagnosis
          JOIN episode e
            ON dr.id_episode = e.id_episode
         WHERE dr.flg_status = 'A'
           AND dr.flg_type = 'P'
        UNION
        SELECT -1, 'CAUSE_' || to_char(rn), rn, NULL
          FROM (SELECT LEVEL rn
                  FROM dual
                CONNECT BY LEVEL < 8)
         WHERE rn NOT IN (SELECT dc.death_cause_rank
                            FROM death_cause dc
                            JOIN death_registry dr
                              ON dr.id_death_registry = dc.id_death_registry
                           WHERE dr.flg_status = 'A'
                             AND dr.flg_type = 'P')
        UNION ALL
        SELECT -1, ds.internal_name, ds.id_ds_component, NULL xvalue
          FROM v_death_pat_comp_aux v_list
          JOIN ds_component ds
            ON v_list.id_ds_component = ds.id_ds_component
         WHERE ds.id_ds_component NOT IN (SELECT DISTINCT id_ds_component
                                            FROM death_registry_det drd
                                            JOIN death_registry dr
                                              ON drd.id_death_registry = dr.id_death_registry
                                           WHERE dr.flg_status = 'A'
                                             AND dr.flg_type = 'P')) xmain
;
