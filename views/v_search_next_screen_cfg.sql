create or replace view v_SEARCH_NEXT_SCREEN_cfg as 
select 
ct.config_table               config_table,
ct.id_record                  id_sys_button_prop,
sbp.screen_name               sbp_screen_name,
sbp.id_btn_prp_parent         id_btn_prp_parent,
sbp.id_sys_screen_area        id_sys_screen_area,
sbp.id_sys_application_area   id_sys_application_area,
sbp.id_sys_button             id_sys_button,
ct.id_config                  id_config,
ct.id_inst_owner              id_inst_owner,
ct.field_01                   next_screen
from config_table ct
join sys_button_prop sbp on sbp.id_sys_button_prop = ct.id_record
where ct.config_table = 'SEARCH_NEXT_SCREEN'
;