-- Create external data table
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;
BEGIN
    

    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_AUX_SW_DISTINCT',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'EXT');
    
    run_ddl(i_sql => '
                CREATE TABLE STT_REV_AUX_SW_DISTINCT (intern_name_sample_text_type VARCHAR2(200),
                                                    id_software NUMBER(24, 0),
                                                    desc_pt_1 VARCHAR2(4000),
                                                    desc_br_11 VARCHAR2(4000),
                                                    desc_en_2 VARCHAR2(4000),
                                                    desc_uk_7 VARCHAR2(4000),
                                                    desc_es_3 VARCHAR2(4000),
                                                    desc_cl_16 VARCHAR2(4000),
                                                    desc_mx_17 VARCHAR2(4000),
                                                    desc_fr_6 VARCHAR2(4000))
                  ORGANIZATION EXTERNAL(DEFAULT DIRECTORY DATA_IMP_DIR
                  ACCESS PARAMETERS(RECORDS
                             SKIP 1
                             DELIMITED BY NEWLINE
                             FIELDS TERMINATED BY '';''
                             MISSING FIELD VALUES ARE NULL)
                  LOCATION(''mig_stt_rev_01_01_translation_sw_distinct.csv'')) REJECT LIMIT 0');


          

    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_AUX_SW_ALL',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'EXT');


    run_ddl(i_sql => '
                CREATE TABLE STT_REV_AUX_SW_ALL (intern_name_sample_text_type VARCHAR2(200),
                                               desc_pt_1 VARCHAR2(4000),
                                               desc_br_11 VARCHAR2(4000),
                                               desc_en_2 VARCHAR2(4000),
                                               desc_uk_7 VARCHAR2(4000),
                                               desc_es_3 VARCHAR2(4000),
                                               desc_cl_16 VARCHAR2(4000),
                                               desc_mx_17 VARCHAR2(4000),
                                               desc_fr_6 VARCHAR2(4000))
                  ORGANIZATION EXTERNAL(DEFAULT DIRECTORY DATA_IMP_DIR
                  ACCESS PARAMETERS(RECORDS
                             SKIP 1
                             DELIMITED BY NEWLINE
                             FIELDS TERMINATED BY '';''
                             MISSING FIELD VALUES ARE NULL)
                  LOCATION(''mig_stt_rev_01_01_translation_sw_all.csv'')) REJECT LIMIT 0');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/

-- Check migration completed to sw_all
DECLARE
    completed VARCHAR2(100);
BEGIN
    SELECT decode(COUNT(1),
                  0,
                  'Migration completed, Ok! on sw_all',
                  'Migration NOT completed - sw_all Dif: ' || COUNT(1))
      INTO completed
      FROM stt_rev_aux_sw_all sttrev
      JOIN sample_text_type stt
        ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
      JOIN translation t
        ON t.code_translation = stt.code_sample_text_type
     WHERE stt.flg_available = 'Y'
       AND (t.desc_lang_1 <> sttrev.desc_pt_1 OR t.desc_lang_2 <> sttrev.desc_en_2 OR t.desc_lang_3 <> sttrev.desc_es_3 OR
           t.desc_lang_6 <> sttrev.desc_fr_6 OR t.desc_lang_7 <> sttrev.desc_uk_7 OR
           t.desc_lang_11 <> sttrev.desc_br_11 OR t.desc_lang_16 <> sttrev.desc_cl_16 OR
           t.desc_lang_17 <> sttrev.desc_mx_17);

    dbms_output.new_line;
    dbms_output.put_line(completed);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - on query to stt_rev_aux_sw_all sttrev' ||
                             REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/

-- Check migration completed to sw_distinct
DECLARE
    completed VARCHAR2(100);
BEGIN
    SELECT decode(COUNT(1),
                  0,
                  'Migration completed, Ok! on sw_distinct',
                  'Migration NOT completed - sw_distinct Dif: ' || COUNT(1))
      INTO completed
      FROM stt_rev_aux_sw_distinct sttrev
      JOIN sample_text_type stt
        ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
       AND sttrev.id_software = stt.id_software
      JOIN translation t
        ON t.code_translation = stt.code_sample_text_type
     WHERE stt.flg_available = 'Y'
       AND (t.desc_lang_1 <> sttrev.desc_pt_1 OR t.desc_lang_2 <> sttrev.desc_en_2 OR t.desc_lang_3 <> sttrev.desc_es_3 OR
           t.desc_lang_6 <> sttrev.desc_fr_6 OR t.desc_lang_7 <> sttrev.desc_uk_7 OR
           t.desc_lang_11 <> sttrev.desc_br_11 OR t.desc_lang_16 <> sttrev.desc_cl_16 OR
           t.desc_lang_17 <> sttrev.desc_mx_17);

    dbms_output.put_line(completed);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - on query to stt_rev_aux_sw_distinct sttrev' ||
                             REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/

-- Diference sw_all (should be null at the end of migration)
-- if not null at the end of migration please save this query results
SELECT t.*, sttrev.*
  FROM stt_rev_aux_sw_all sttrev
  JOIN sample_text_type stt
    ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
  JOIN translation t
    ON t.code_translation = stt.code_sample_text_type
 WHERE stt.flg_available = 'Y'
   AND (t.desc_lang_1 <> sttrev.desc_pt_1 OR t.desc_lang_2 <> sttrev.desc_en_2 OR t.desc_lang_3 <> sttrev.desc_es_3 OR
       t.desc_lang_6 <> sttrev.desc_fr_6 OR t.desc_lang_7 <> sttrev.desc_uk_7 OR t.desc_lang_11 <> sttrev.desc_br_11 OR
       t.desc_lang_16 <> sttrev.desc_cl_16 OR t.desc_lang_17 <> sttrev.desc_mx_17);
/
       
-- Diference sw_distinct (should be null at the end of migration)
-- if not null at the end of migration please save this query results
SELECT t.*, sttrev.*
  FROM stt_rev_aux_sw_distinct sttrev
  JOIN sample_text_type stt
    ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
   AND sttrev.id_software = stt.id_software
  JOIN translation t
    ON t.code_translation = stt.code_sample_text_type
 WHERE stt.flg_available = 'Y'
   AND (t.desc_lang_1 <> sttrev.desc_pt_1 OR t.desc_lang_2 <> sttrev.desc_en_2 OR t.desc_lang_3 <> sttrev.desc_es_3 OR
       t.desc_lang_6 <> sttrev.desc_fr_6 OR t.desc_lang_7 <> sttrev.desc_uk_7 OR t.desc_lang_11 <> sttrev.desc_br_11 OR
       t.desc_lang_16 <> sttrev.desc_cl_16 OR t.desc_lang_17 <> sttrev.desc_mx_17);
/

-- Drop external data table
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;
BEGIN
    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_DISTINCT');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_DISTINCT');
    run_ddl(i_sql => 'DROP TABLE stt_rev_aux_sw_distinct');

    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_ALL');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_SW_ALL');
    run_ddl(i_sql => 'DROP TABLE stt_rev_aux_sw_all');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/
