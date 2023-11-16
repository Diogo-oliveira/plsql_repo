
CREATE OR REPLACE VIEW v_sys_config_translation AS
SELECT 'insert_into_syscfg_translation(' || id_language || ',''' ||
       REPLACE(REPLACE(id_sys_config, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''',''' ||
       REPLACE(REPLACE(desc_config, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''',''' ||
       REPLACE(REPLACE(desc_functionality, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''');' query_insert,
       'UPDATE sys_config_translation SET desc_config = ''' ||
       REPLACE(REPLACE(desc_config, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') ||
       ''', desc_functionality = ''' ||
       REPLACE(REPLACE(desc_functionality, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') ||
       ''' where id_sys_config = ''' ||
       REPLACE(REPLACE(id_sys_config, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''' AND id_language = ' ||
       id_language || ';' query_update,
       s.*
  FROM sys_config_translation s;

  