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
		
    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_REP_MASTER');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_REP_MASTER');
  	run_ddl('DROP TABLE stt_rev_aux_rep_master');
		
    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_PREVAIL');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_PREVAIL');
    run_ddl('DROP MATERIALIZED VIEW stt_rev_aux_prevail');

    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_DEPRECATE');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_DEPRECATE');
    run_ddl('DROP MATERIALIZED VIEW stt_rev_aux_deprecate');

    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_REPLACE');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_AUX_REPLACE');
    run_ddl('DROP MATERIALIZED VIEW stt_rev_aux_replace');
		
    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_SAMPLE_TEXT_TYPE');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_SAMPLE_TEXT_TYPE');
    run_ddl('DROP MATERIALIZED VIEW STT_REV_SAV_SAMPLE_TEXT_TYPE');

    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_SAMPLE_TEXT');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_SAMPLE_TEXT');
    run_ddl('DROP MATERIALIZED VIEW STT_REV_SAV_SAMPLE_TEXT');

    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_STTC_INS');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_STTC_INS');
    run_ddl('DROP MATERIALIZED VIEW STT_REV_SAV_STTC_INS');

    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_STTC_DEL');
    pk_frmw_objects.delete_columns(i_owner => 'ALERT', i_obj_name => 'STT_REV_SAV_STTC_DEL');
    run_ddl('DROP MATERIALIZED VIEW STT_REV_SAV_STTC_DEL');
		
    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_AUX_REP_MASTER',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'JNK');

    run_ddl(i_sql => '
					 CREATE TABLE STT_REV_AUX_REP_MASTER (intern_name_sample_text_type VARCHAR2(200),
																						 id_software                  NUMBER(24),  
																						 id_content_master            VARCHAR2(200))
									ORGANIZATION EXTERNAL(DEFAULT DIRECTORY DATA_IMP_DIR
									ACCESS PARAMETERS(RECORDS
														 SKIP 1
														 DELIMITED BY 0x ''0d0a''
														 FIELDS TERMINATED BY '';''
														 MISSING FIELD VALUES ARE NULL)
									LOCATION(''mig_stt_rev_02_01_remove_repetitions_master.csv'')) REJECT LIMIT 0');

    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_AUX_PREVAIL',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'JNK');

    -- Uma vez que podem ser designados 2 id_content master para o mesmo (internal_name + sw)
    -- garante que não há conflitos de masters num dado domínio (instalação), rejeitando as repetições que surjam     
    run_ddl(i_sql => '								
						CREATE MATERIALIZED VIEW stt_rev_aux_prevail AS
						SELECT stt1.*
							FROM sample_text_type stt1
							JOIN stt_rev_aux_rep_master sttm1
								ON stt1.intern_name_sample_text_type = sttm1.intern_name_sample_text_type
							 AND stt1.id_software = sttm1.id_software
							 AND stt1.id_content = sttm1.id_content_master
						 WHERE stt1.flg_available = ''Y''
							 AND NOT EXISTS (SELECT 1
											FROM sample_text_type stt2
											JOIN stt_rev_aux_rep_master sttm2
												ON stt2.intern_name_sample_text_type = sttm2.intern_name_sample_text_type
											 AND stt2.id_software = sttm2.id_software
											 AND stt2.id_content = sttm2.id_content_master
										 WHERE stt2.flg_available = ''Y''
											 AND stt1.intern_name_sample_text_type = stt2.intern_name_sample_text_type
											 AND stt1.id_software = stt2.id_software
											 AND stt1.id_sample_text_type <> stt2.id_sample_text_type)');

    EXECUTE IMMEDIATE 'GRANT SELECT On stt_rev_aux_prevail TO alert_default';

    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_AUX_DEPRECATE',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'JNK');

    run_ddl(i_sql => '	
						CREATE MATERIALIZED VIEW stt_rev_aux_deprecate AS
								SELECT stt.*,
											 nvl((SELECT DISTINCT ''Y''
														 FROM sample_text_type_cat sttc
														WHERE sttc.id_sample_text_type = stt.id_sample_text_type),
													 ''N'') configured
									FROM sample_text_type stt
									JOIN stt_rev_aux_prevail sttprv
										ON stt.intern_name_sample_text_type = sttprv.intern_name_sample_text_type
									 AND stt.id_software = sttprv.id_software
								 WHERE stt.flg_available = ''Y''
									 AND (stt.id_sample_text_type <> sttprv.id_sample_text_type)');

    EXECUTE IMMEDIATE 'GRANT SELECT ON stt_rev_aux_deprecate TO alert_default';

    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_AUX_REPLACE',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'JNK');

    run_ddl(i_sql => '	
						CREATE MATERIALIZED VIEW stt_rev_aux_replace AS
								SELECT sttdep.id_sample_text_type id_sample_text_type_deprecate,
											 sttprv.id_sample_text_type id_sample_text_type_prevail
									FROM stt_rev_aux_deprecate sttdep
									JOIN stt_rev_aux_prevail sttprv
										ON sttdep.intern_name_sample_text_type = sttprv.intern_name_sample_text_type
									 AND sttdep.id_software = sttprv.id_software');

    EXECUTE IMMEDIATE 'GRANT SELECT ON stt_rev_aux_replace TO ALERT_DEFAULT';

    -- Record State sample_text_type
    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_SAV_SAMPLE_TEXT_TYPE',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC');

    run_ddl(i_sql => '	
						CREATE MATERIALIZED VIEW STT_REV_SAV_SAMPLE_TEXT_TYPE AS
						SELECT stt.*
							FROM sample_text_type stt
						 WHERE stt.id_sample_text_type IN (SELECT sttdep.id_sample_text_type
																								 FROM stt_rev_aux_deprecate sttdep)');

    -- Record State sample_text
    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_SAV_SAMPLE_TEXT',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC');

    run_ddl(i_sql => '	
						CREATE MATERIALIZED VIEW STT_REV_SAV_SAMPLE_TEXT AS
						SELECT st.*
							FROM sample_text st
							JOIN stt_rev_aux_deprecate sttdep
								ON st.id_sample_text_type = sttdep.id_sample_text_type
						 WHERE sttdep.configured = ''Y''');

    -- Record State sample_text_prof
    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_SAV_SAMPLE_TEXT_PROF',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC',
																						 i_flg_nzd => 'Y');

		run_ddl(i_sql => '
						CREATE TABLE stt_rev_sav_sample_text_prof AS
						SELECT stp.*, SYSDATE backup_date
							FROM sample_text_prof stp
						 WHERE 1 = 0 ');

    -- Record State alert.sample_text_type_cat Before INSERT
    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_SAV_STTC_INS',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC');

    run_ddl(i_sql => '
						CREATE MATERIALIZED VIEW STT_REV_SAV_STTC_INS AS
								SELECT sttc2.id_sample_text_type_prevail,
											 sttc2.id_category,
											 sttc2.id_institution,
											 sysdate
									FROM (SELECT DISTINCT sttrpl.id_sample_text_type_prevail, sttc.id_category, sttc.id_institution
													FROM alert.sample_text_type_cat sttc
													JOIN stt_rev_aux_replace sttrpl
														ON sttc.id_sample_text_type = sttrpl.id_sample_text_type_deprecate
												 WHERE (sttrpl.id_sample_text_type_prevail, sttc.id_category, sttc.id_institution) NOT IN
															 (SELECT sttc1.id_sample_text_type, sttc1.id_category, sttc1.id_institution
																	FROM alert.sample_text_type_cat sttc1)
											 ) sttc2');

    -- Record State alert.sample_text_type_cat BEFORE DELETE
    pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                             i_obj_name     => 'STT_REV_SAV_STTC_DEL',
                                             i_obj_type     => 'TABLE',
                                             i_flg_category => 'DPC');

    run_ddl(i_sql => '
						CREATE MATERIALIZED VIEW STT_REV_SAV_STTC_DEL AS
						SELECT * FROM alert.sample_text_type_cat sttc
						 WHERE sttc.id_sample_text_type_cat IN
									 (SELECT sttc1.id_sample_text_type_cat
											FROM alert.sample_text_type_cat sttc1
											JOIN stt_rev_aux_deprecate sttdep
												ON sttc1.id_sample_text_type = sttdep.id_sample_text_type)');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/
