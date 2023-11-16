
CREATE OR REPLACE VIEW v_sys_domain AS
SELECT 'pk_sysdomain.insert_into_sys_domain(i_lang=>' || id_language || ', i_code_domain=>''' ||
       REPLACE(REPLACE(code_domain, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''', i_desc_val=> ''' ||
       REPLACE(REPLACE(desc_val, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''', i_val=>''' || val ||
       ''', i_rank=>' || rank || ', i_img_name=>''' || img_name || ''');' query_insert,
       'UPDATE sys_domain SET desc_val = ''' ||
       REPLACE(REPLACE(desc_val, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''' WHERE code_domain = ''' ||
       REPLACE(REPLACE(code_domain, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''' AND val = ''' || val ||
       ''' AND id_language = ' || id_language || ';' query_update,
       'UPDATE sys_domain SET img_name = ''' ||
       REPLACE(REPLACE(img_name, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''' WHERE code_domain = ''' ||
       REPLACE(REPLACE(code_domain, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''' AND val = ''' || val ||
       ''' AND id_language = ' || id_language || ';' query_update_icon,
       s.*
  FROM sys_domain s
 ORDER BY id_language, code_domain, val;

