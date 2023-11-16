
CREATE OR REPLACE VIEW v_sys_message AS
SELECT CASE
            WHEN length_message < 3863 THEN
             'pk_message.insert_into_sys_message(i_lang=>' || id_language || ',i_code_message=>''' || code_message ||
             ''', i_desc_message=>''' ||
             REPLACE(REPLACE(desc_message, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''', i_flg_type=>''' ||
             flg_type || ''', i_software=>' || id_software || ', i_institution=>' || id_institution || ', i_img_name=>''' ||
             img_name || ''');'
        END query_insert,
       CASE
            WHEN length_message < 3840 THEN
             'pk_message.insert_into_sys_message(i_lang=>' || id_language || ',i_code_message=>''' || code_message ||
             ''', i_desc_message=>''' ||
             REPLACE(REPLACE(desc_message, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''', i_flg_type=>''' ||
             flg_type || ''', i_software=>' || id_software || ', i_institution=>' || id_institution || ', i_img_name=>''' ||
             img_name || ''', i_id_sys_message=>' || id_sys_message || ');'
        END query_insert_with_id,
       CASE
            WHEN length_message < 3918 THEN
             'UPDATE sys_message SET desc_message = ''' ||
             REPLACE(REPLACE(desc_message, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') ||
             ''' WHERE code_message = ''' || code_message || ''' AND id_language = ' || id_language || ';'
        END query_update,
       CASE
            WHEN length_message < 3851 THEN
             'UPDATE sys_message SET desc_message = ''' ||
             REPLACE(REPLACE(desc_message, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') ||
             ''' WHERE code_message = ''' || code_message || ''' AND id_language = ' || id_language ||
             ' AND id_institution = ' || id_institution || ' AND id_software = ' || id_software || ';'
        END query_update_soft_isnt,
				       CASE
            WHEN length_message < 3918 THEN
             'UPDATE sys_message SET img_name = ''' ||
             REPLACE(REPLACE(img_name, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') ||
             ''' WHERE code_message = ''' || code_message || ''' AND id_language = ' || id_language || ' AND id_software = ' || id_software ||';'
        END query_update_icon,
       t.*
  FROM (SELECT s.*,
               length(id_language) + length(code_message) + length(desc_message) + length(flg_type) +
               length(to_char(id_software)) + length(to_char(id_institution)) + nvl(length(img_name), 0) length_message
          FROM sys_message s
         ORDER BY id_language, code_message) t;


