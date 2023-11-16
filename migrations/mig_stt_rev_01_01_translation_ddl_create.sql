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
														 DELIMITED BY 0x ''0d0a''
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
														 DELIMITED BY 0x ''0d0a''
														 FIELDS TERMINATED BY '';''
														 MISSING FIELD VALUES ARE NULL)
									LOCATION(''mig_stt_rev_01_01_translation_sw_all.csv'')) REJECT LIMIT 0');

-- Record State translation before UPDATE

    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_SAV_TRANSLATION_UPD',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC');

    run_ddl(i_sql => '
								CREATE MATERIALIZED VIEW STT_REV_SAV_TRANSLATION_UPD AS
								SELECT t.*
									FROM stt_rev_aux_sw_distinct sttrev
									JOIN sample_text_type stt
										ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
									 AND sttrev.id_software = stt.id_software
									JOIN translation t
										ON stt.code_sample_text_type = t.code_translation
								 WHERE stt.flg_available = ''Y''
								UNION
								SELECT t.*
									FROM stt_rev_aux_sw_all sttrev
									JOIN sample_text_type stt
										ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
									JOIN translation t
										ON stt.code_sample_text_type = t.code_translation
								 WHERE stt.flg_available = ''Y''');



-- Record State translation before INSERT

    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_SAV_TRANSLATION_INS',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC');

    run_ddl(i_sql => '
						 CREATE MATERIALIZED VIEW STT_REV_SAV_TRANSLATION_INS AS
						 SELECT stt.code_sample_text_type
							 FROM stt_rev_aux_sw_distinct sttrev
							 JOIN sample_text_type stt
								 ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
								AND sttrev.id_software = stt.id_software
							WHERE stt.flg_available = ''Y''
								AND stt.code_sample_text_type NOT IN (SELECT t.code_translation
																												FROM translation t)
							UNION
						 SELECT stt.code_sample_text_type
							 FROM stt_rev_aux_sw_all sttrev
							 JOIN sample_text_type stt
								 ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
							WHERE stt.flg_available = ''Y''
								AND stt.code_sample_text_type NOT IN (SELECT t.code_translation
																												FROM translation t)');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/




