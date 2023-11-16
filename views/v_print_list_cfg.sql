create or replace view v_print_list_cfg as
SELECT cfg.id_record         id_print_list_area,
       cfg.field_01          flg_replace_similar_jobs,
       cfg.field_02          n_days_after_epis_inactivation,
       cfg.field_03          flg_print_option_default,
       cfg.id_config         id_config,
       c.id_market,
       c.id_institution,
       c.id_category,
       c.id_profile_template,
       c.id_software,
       c.id_professional
  FROM v_config_table cfg
  JOIN v_config c
    ON cfg.id_config = c.id_config
 WHERE cfg.config_table = 'PRINT_LIST';
 
comment on column v_print_list_cfg.id_print_list_area is 'Print list area identifier';
comment on column v_print_list_cfg.flg_replace_similar_jobs is 'Y- Replace similar print jobs in printing list, N- otherwise';
comment on column v_print_list_cfg.n_days_after_epis_inactivation is 'Number of days after episode inactivation, to clean this print list';
comment on column v_print_list_cfg.flg_print_option_default is 'SAVE_PRINT_LIST- Add to Print List, SAVE_PRINT- Print';
comment on column v_print_list_cfg.id_config is 'Configuration identifier';
comment on column v_print_list_cfg.id_market is 'Market identifier';
comment on column v_print_list_cfg.id_institution is 'Institution identifier';
comment on column v_print_list_cfg.id_category is 'Category identifier';
comment on column v_print_list_cfg.id_profile_template is 'Profile template identifier';
comment on column v_print_list_cfg.id_software is 'Software identifier';
comment on column v_print_list_cfg.id_professional is 'Professional identifier';
