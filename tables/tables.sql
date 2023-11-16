set feedback off
set termout off
set echo off
set heading off
set verify off
set pau off
set long 10000
set lines 10000
set trims on
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'TABLESPACE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'CONSTRAINTS_AS_ALTER', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', true)
col text format A10000 word wrap

spool 'c:\mighdc\alert\tables\abnormality.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ABNORMALITY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ABNORMALITY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ABNORMALITY ', 'ALL',a.table_name, 'ABNORMALITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ABNORMALITY ','ALL',a.table_name, 'ABNORMALITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\abnormality_nature.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ABNORMALITY_NATURE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ABNORMALITY_NATURE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ABNORMALITY_NATURE ', 'ALL',a.table_name, 'ABNORMALITY_NATURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ABNORMALITY_NATURE ','ALL',a.table_name, 'ABNORMALITY_NATURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\action_criteria.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ACTION_CRITERIA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ACTION_CRITERIA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ACTION_CRITERIA ', 'ALL',a.table_name, 'ACTION_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ACTION_CRITERIA ','ALL',a.table_name, 'ACTION_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\adverse_exam_allergy.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ADVERSE_EXAM_ALLERGY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ADVERSE_EXAM_ALLERGY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ADVERSE_EXAM_ALLERGY ', 'ALL',a.table_name, 'ADVERSE_EXAM_ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ADVERSE_EXAM_ALLERGY ','ALL',a.table_name, 'ADVERSE_EXAM_ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\adverse_interv_allergy.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ADVERSE_INTERV_ALLERGY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ADVERSE_INTERV_ALLERGY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ADVERSE_INTERV_ALLERGY ', 'ALL',a.table_name, 'ADVERSE_INTERV_ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ADVERSE_INTERV_ALLERGY ','ALL',a.table_name, 'ADVERSE_INTERV_ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\allergy.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ALLERGY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ALLERGY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ALLERGY ', 'ALL',a.table_name, 'ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ALLERGY ','ALL',a.table_name, 'ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\allergy_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ALLERGY_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ALLERGY_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ALLERGY_EXT_SYS ', 'ALL',a.table_name, 'ALLERGY_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ALLERGY_EXT_SYS ','ALL',a.table_name, 'ALLERGY_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\allocation_bed.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ALLOCATION_BED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ALLOCATION_BED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ALLOCATION_BED ', 'ALL',a.table_name, 'ALLOCATION_BED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ALLOCATION_BED ','ALL',a.table_name, 'ALLOCATION_BED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\allocation_bed_10042007.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ALLOCATION_BED_10042007','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ALLOCATION_BED_10042007','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ALLOCATION_BED_10042007 ', 'ALL',a.table_name, 'ALLOCATION_BED_10042007') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ALLOCATION_BED_10042007 ','ALL',a.table_name, 'ALLOCATION_BED_10042007') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\analy_parm_limit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALY_PARM_LIMIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALY_PARM_LIMIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALY_PARM_LIMIT ', 'ALL',a.table_name, 'ANALY_PARM_LIMIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALY_PARM_LIMIT ','ALL',a.table_name, 'ANALY_PARM_LIMIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS ', 'ALL',a.table_name, 'ANALYSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS ','ALL',a.table_name, 'ANALYSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\analysis_agp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_AGP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_AGP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_AGP ', 'ALL',a.table_name, 'ANALYSIS_AGP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_AGP ','ALL',a.table_name, 'ANALYSIS_AGP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_agp_old.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_AGP_OLD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_AGP_OLD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_AGP_OLD ', 'ALL',a.table_name, 'ANALYSIS_AGP_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_AGP_OLD ','ALL',a.table_name, 'ANALYSIS_AGP_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\analysis_alias.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_ALIAS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_ALIAS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_ALIAS ', 'ALL',a.table_name, 'ANALYSIS_ALIAS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_ALIAS ','ALL',a.table_name, 'ANALYSIS_ALIAS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_DEP_CLIN_SERV ', 'ALL',a.table_name, 'ANALYSIS_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_DEP_CLIN_SERV ','ALL',a.table_name, 'ANALYSIS_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_dep_clin_serv_old.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_DEP_CLIN_SERV_OLD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_DEP_CLIN_SERV_OLD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_DEP_CLIN_SERV_OLD ', 'ALL',a.table_name, 'ANALYSIS_DEP_CLIN_SERV_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_DEP_CLIN_SERV_OLD ','ALL',a.table_name, 'ANALYSIS_DEP_CLIN_SERV_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_desc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_DESC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_DESC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_DESC ', 'ALL',a.table_name, 'ANALYSIS_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_DESC ','ALL',a.table_name, 'ANALYSIS_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_ext_sys_delete.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_EXT_SYS_DELETE ', 'ALL',a.table_name, 'ANALYSIS_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_EXT_SYS_DELETE ','ALL',a.table_name, 'ANALYSIS_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_GROUP ', 'ALL',a.table_name, 'ANALYSIS_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_GROUP ','ALL',a.table_name, 'ANALYSIS_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_harvest.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_HARVEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_HARVEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_HARVEST ', 'ALL',a.table_name, 'ANALYSIS_HARVEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_HARVEST ','ALL',a.table_name, 'ANALYSIS_HARVEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_instit_soft.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_INSTIT_SOFT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_INSTIT_SOFT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_INSTIT_SOFT ', 'ALL',a.table_name, 'ANALYSIS_INSTIT_SOFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_INSTIT_SOFT ','ALL',a.table_name, 'ANALYSIS_INSTIT_SOFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_loinc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_LOINC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_LOINC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_LOINC ', 'ALL',a.table_name, 'ANALYSIS_LOINC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_LOINC ','ALL',a.table_name, 'ANALYSIS_LOINC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\analysis_loinc_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_LOINC_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_LOINC_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_LOINC_TEMPLATE ', 'ALL',a.table_name, 'ANALYSIS_LOINC_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_LOINC_TEMPLATE ','ALL',a.table_name, 'ANALYSIS_LOINC_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_old.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_OLD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_OLD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_OLD ', 'ALL',a.table_name, 'ANALYSIS_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_OLD ','ALL',a.table_name, 'ANALYSIS_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\analysis_param.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_PARAM ', 'ALL',a.table_name, 'ANALYSIS_PARAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_PARAM ','ALL',a.table_name, 'ANALYSIS_PARAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_parameter.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAMETER','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAMETER','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_PARAMETER ', 'ALL',a.table_name, 'ANALYSIS_PARAMETER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_PARAMETER ','ALL',a.table_name, 'ANALYSIS_PARAMETER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\analysis_param_instit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAM_INSTIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAM_INSTIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_PARAM_INSTIT ', 'ALL',a.table_name, 'ANALYSIS_PARAM_INSTIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_PARAM_INSTIT ','ALL',a.table_name, 'ANALYSIS_PARAM_INSTIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_param_instit_sample.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAM_INSTIT_SAMPLE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PARAM_INSTIT_SAMPLE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_PARAM_INSTIT_SAMPLE ', 'ALL',a.table_name, 'ANALYSIS_PARAM_INSTIT_SAMPLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_PARAM_INSTIT_SAMPLE ','ALL',a.table_name, 'ANALYSIS_PARAM_INSTIT_SAMPLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_prep_mesg.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PREP_MESG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PREP_MESG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_PREP_MESG ', 'ALL',a.table_name, 'ANALYSIS_PREP_MESG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_PREP_MESG ','ALL',a.table_name, 'ANALYSIS_PREP_MESG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_PROTOCOLS ', 'ALL',a.table_name, 'ANALYSIS_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_PROTOCOLS ','ALL',a.table_name, 'ANALYSIS_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_protocols_old.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PROTOCOLS_OLD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_PROTOCOLS_OLD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_PROTOCOLS_OLD ', 'ALL',a.table_name, 'ANALYSIS_PROTOCOLS_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_PROTOCOLS_OLD ','ALL',a.table_name, 'ANALYSIS_PROTOCOLS_OLD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_REQ ', 'ALL',a.table_name, 'ANALYSIS_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_REQ ','ALL',a.table_name, 'ANALYSIS_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_req_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_REQ_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_REQ_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_REQ_DET ', 'ALL',a.table_name, 'ANALYSIS_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_REQ_DET ','ALL',a.table_name, 'ANALYSIS_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_req_par.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_REQ_PAR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_REQ_PAR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_REQ_PAR ', 'ALL',a.table_name, 'ANALYSIS_REQ_PAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_REQ_PAR ','ALL',a.table_name, 'ANALYSIS_REQ_PAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_result.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_RESULT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_RESULT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_RESULT ', 'ALL',a.table_name, 'ANALYSIS_RESULT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_RESULT ','ALL',a.table_name, 'ANALYSIS_RESULT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\analysis_result_par.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_RESULT_PAR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_RESULT_PAR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_RESULT_PAR ', 'ALL',a.table_name, 'ANALYSIS_RESULT_PAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_RESULT_PAR ','ALL',a.table_name, 'ANALYSIS_RESULT_PAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\analysis_room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_ROOM ', 'ALL',a.table_name, 'ANALYSIS_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_ROOM ','ALL',a.table_name, 'ANALYSIS_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\analysis_unit_measure.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_UNIT_MEASURE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANALYSIS_UNIT_MEASURE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANALYSIS_UNIT_MEASURE ', 'ALL',a.table_name, 'ANALYSIS_UNIT_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANALYSIS_UNIT_MEASURE ','ALL',a.table_name, 'ANALYSIS_UNIT_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\anesthesia_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ANESTHESIA_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ANESTHESIA_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ANESTHESIA_TYPE ', 'ALL',a.table_name, 'ANESTHESIA_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ANESTHESIA_TYPE ','ALL',a.table_name, 'ANESTHESIA_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\bed.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BED ', 'ALL',a.table_name, 'BED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BED ','ALL',a.table_name, 'BED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\bed_schedule.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BED_SCHEDULE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BED_SCHEDULE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BED_SCHEDULE ', 'ALL',a.table_name, 'BED_SCHEDULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BED_SCHEDULE ','ALL',a.table_name, 'BED_SCHEDULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\beye_view_screen.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BEYE_VIEW_SCREEN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BEYE_VIEW_SCREEN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BEYE_VIEW_SCREEN ', 'ALL',a.table_name, 'BEYE_VIEW_SCREEN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BEYE_VIEW_SCREEN ','ALL',a.table_name, 'BEYE_VIEW_SCREEN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\birds_eye_view.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BIRDS_EYE_VIEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BIRDS_EYE_VIEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BIRDS_EYE_VIEW ', 'ALL',a.table_name, 'BIRDS_EYE_VIEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BIRDS_EYE_VIEW ','ALL',a.table_name, 'BIRDS_EYE_VIEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\board.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BOARD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BOARD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BOARD ', 'ALL',a.table_name, 'BOARD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BOARD ','ALL',a.table_name, 'BOARD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\board_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BOARD_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BOARD_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BOARD_GROUP ', 'ALL',a.table_name, 'BOARD_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BOARD_GROUP ','ALL',a.table_name, 'BOARD_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\board_grouping.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BOARD_GROUPING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BOARD_GROUPING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BOARD_GROUPING ', 'ALL',a.table_name, 'BOARD_GROUPING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BOARD_GROUPING ','ALL',a.table_name, 'BOARD_GROUPING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\body_part.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BODY_PART','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BODY_PART','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BODY_PART ', 'ALL',a.table_name, 'BODY_PART') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BODY_PART ','ALL',a.table_name, 'BODY_PART') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\body_part_image.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BODY_PART_IMAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BODY_PART_IMAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BODY_PART_IMAGE ', 'ALL',a.table_name, 'BODY_PART_IMAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BODY_PART_IMAGE ','ALL',a.table_name, 'BODY_PART_IMAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\bp_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BP_CLIN_SERV ', 'ALL',a.table_name, 'BP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BP_CLIN_SERV ','ALL',a.table_name, 'BP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\building.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','BUILDING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','BUILDING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('BUILDING ', 'ALL',a.table_name, 'BUILDING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('BUILDING ','ALL',a.table_name, 'BUILDING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\category.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CATEGORY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CATEGORY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CATEGORY ', 'ALL',a.table_name, 'CATEGORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CATEGORY ','ALL',a.table_name, 'CATEGORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\category_sub.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CATEGORY_SUB','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CATEGORY_SUB','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CATEGORY_SUB ', 'ALL',a.table_name, 'CATEGORY_SUB') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CATEGORY_SUB ','ALL',a.table_name, 'CATEGORY_SUB') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\ch_contents.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CH_CONTENTS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CH_CONTENTS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CH_CONTENTS ', 'ALL',a.table_name, 'CH_CONTENTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CH_CONTENTS ','ALL',a.table_name, 'CH_CONTENTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\ch_contents_text.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CH_CONTENTS_TEXT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CH_CONTENTS_TEXT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CH_CONTENTS_TEXT ', 'ALL',a.table_name, 'CH_CONTENTS_TEXT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CH_CONTENTS_TEXT ','ALL',a.table_name, 'CH_CONTENTS_TEXT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\child_feed_dev.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CHILD_FEED_DEV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CHILD_FEED_DEV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CHILD_FEED_DEV ', 'ALL',a.table_name, 'CHILD_FEED_DEV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CHILD_FEED_DEV ','ALL',a.table_name, 'CHILD_FEED_DEV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\clinical_service.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CLINICAL_SERVICE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CLINICAL_SERVICE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CLINICAL_SERVICE ', 'ALL',a.table_name, 'CLINICAL_SERVICE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CLINICAL_SERVICE ','ALL',a.table_name, 'CLINICAL_SERVICE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\clin_record.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CLIN_RECORD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CLIN_RECORD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CLIN_RECORD ', 'ALL',a.table_name, 'CLIN_RECORD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CLIN_RECORD ','ALL',a.table_name, 'CLIN_RECORD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\clin_serv_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CLIN_SERV_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CLIN_SERV_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CLIN_SERV_EXT_SYS ', 'ALL',a.table_name, 'CLIN_SERV_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CLIN_SERV_EXT_SYS ','ALL',a.table_name, 'CLIN_SERV_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\clin_srv_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CLIN_SRV_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CLIN_SRV_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CLIN_SRV_TYPE ', 'ALL',a.table_name, 'CLIN_SRV_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CLIN_SRV_TYPE ','ALL',a.table_name, 'CLIN_SRV_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\cli_rec_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CLI_REC_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CLI_REC_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CLI_REC_REQ ', 'ALL',a.table_name, 'CLI_REC_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CLI_REC_REQ ','ALL',a.table_name, 'CLI_REC_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\cli_rec_req_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CLI_REC_REQ_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CLI_REC_REQ_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CLI_REC_REQ_DET ', 'ALL',a.table_name, 'CLI_REC_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CLI_REC_REQ_DET ','ALL',a.table_name, 'CLI_REC_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\cli_rec_req_mov.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CLI_REC_REQ_MOV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CLI_REC_REQ_MOV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CLI_REC_REQ_MOV ', 'ALL',a.table_name, 'CLI_REC_REQ_MOV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CLI_REC_REQ_MOV ','ALL',a.table_name, 'CLI_REC_REQ_MOV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\color.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','COLOR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','COLOR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('COLOR ', 'ALL',a.table_name, 'COLOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('COLOR ','ALL',a.table_name, 'COLOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\complaint.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('COMPLAINT ', 'ALL',a.table_name, 'COMPLAINT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('COMPLAINT ','ALL',a.table_name, 'COMPLAINT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\complaint_diagnosis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT_DIAGNOSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT_DIAGNOSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('COMPLAINT_DIAGNOSIS ', 'ALL',a.table_name, 'COMPLAINT_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('COMPLAINT_DIAGNOSIS ','ALL',a.table_name, 'COMPLAINT_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\complaint_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('COMPLAINT_TEMPLATE ', 'ALL',a.table_name, 'COMPLAINT_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('COMPLAINT_TEMPLATE ','ALL',a.table_name, 'COMPLAINT_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\complaint_triage_board.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT_TRIAGE_BOARD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLAINT_TRIAGE_BOARD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('COMPLAINT_TRIAGE_BOARD ', 'ALL',a.table_name, 'COMPLAINT_TRIAGE_BOARD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('COMPLAINT_TRIAGE_BOARD ','ALL',a.table_name, 'COMPLAINT_TRIAGE_BOARD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\complete_history.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLETE_HISTORY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','COMPLETE_HISTORY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('COMPLETE_HISTORY ', 'ALL',a.table_name, 'COMPLETE_HISTORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('COMPLETE_HISTORY ','ALL',a.table_name, 'COMPLETE_HISTORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\consult_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CONSULT_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CONSULT_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CONSULT_REQ ', 'ALL',a.table_name, 'CONSULT_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CONSULT_REQ ','ALL',a.table_name, 'CONSULT_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\consult_req_prof.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CONSULT_REQ_PROF','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CONSULT_REQ_PROF','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CONSULT_REQ_PROF ', 'ALL',a.table_name, 'CONSULT_REQ_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CONSULT_REQ_PROF ','ALL',a.table_name, 'CONSULT_REQ_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\contraceptive.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CONTRACEPTIVE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CONTRACEPTIVE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CONTRACEPTIVE ', 'ALL',a.table_name, 'CONTRACEPTIVE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CONTRACEPTIVE ','ALL',a.table_name, 'CONTRACEPTIVE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\contra_indic.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CONTRA_INDIC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CONTRA_INDIC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CONTRA_INDIC ', 'ALL',a.table_name, 'CONTRA_INDIC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CONTRA_INDIC ','ALL',a.table_name, 'CONTRA_INDIC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\country.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','COUNTRY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','COUNTRY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('COUNTRY ', 'ALL',a.table_name, 'COUNTRY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('COUNTRY ','ALL',a.table_name, 'COUNTRY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\create$java$lob$table.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CREATE$JAVA$LOB$TABLE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CREATE$JAVA$LOB$TABLE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CREATE$JAVA$LOB$TABLE ', 'ALL',a.table_name, 'CREATE$JAVA$LOB$TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CREATE$JAVA$LOB$TABLE ','ALL',a.table_name, 'CREATE$JAVA$LOB$TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\criteria.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CRITERIA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CRITERIA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CRITERIA ', 'ALL',a.table_name, 'CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CRITERIA ','ALL',a.table_name, 'CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\critical_care.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CRITICAL_CARE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CRITICAL_CARE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CRITICAL_CARE ', 'ALL',a.table_name, 'CRITICAL_CARE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CRITICAL_CARE ','ALL',a.table_name, 'CRITICAL_CARE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\critical_care_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CRITICAL_CARE_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CRITICAL_CARE_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CRITICAL_CARE_DET ', 'ALL',a.table_name, 'CRITICAL_CARE_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CRITICAL_CARE_DET ','ALL',a.table_name, 'CRITICAL_CARE_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\critical_care_read.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','CRITICAL_CARE_READ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','CRITICAL_CARE_READ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('CRITICAL_CARE_READ ', 'ALL',a.table_name, 'CRITICAL_CARE_READ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('CRITICAL_CARE_READ ','ALL',a.table_name, 'CRITICAL_CARE_READ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\department.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DEPARTMENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DEPARTMENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DEPARTMENT ', 'ALL',a.table_name, 'DEPARTMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DEPARTMENT ','ALL',a.table_name, 'DEPARTMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DEP_CLIN_SERV ', 'ALL',a.table_name, 'DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DEP_CLIN_SERV ','ALL',a.table_name, 'DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dep_clin_serv_type.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DEP_CLIN_SERV_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DEP_CLIN_SERV_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DEP_CLIN_SERV_TYPE ', 'ALL',a.table_name, 'DEP_CLIN_SERV_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DEP_CLIN_SERV_TYPE ','ALL',a.table_name, 'DEP_CLIN_SERV_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dependency.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DEPENDENCY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DEPENDENCY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DEPENDENCY ', 'ALL',a.table_name, 'DEPENDENCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DEPENDENCY ','ALL',a.table_name, 'DEPENDENCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dept.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DEPT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DEPT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DEPT ', 'ALL',a.table_name, 'DEPT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DEPT ','ALL',a.table_name, 'DEPT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dept_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DEPT_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DEPT_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DEPT_TEMPLATE ', 'ALL',a.table_name, 'DEPT_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DEPT_TEMPLATE ','ALL',a.table_name, 'DEPT_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diagnosis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGNOSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGNOSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGNOSIS ', 'ALL',a.table_name, 'DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGNOSIS ','ALL',a.table_name, 'DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diagnosis_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGNOSIS_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGNOSIS_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGNOSIS_DEP_CLIN_SERV ', 'ALL',a.table_name, 'DIAGNOSIS_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGNOSIS_DEP_CLIN_SERV ','ALL',a.table_name, 'DIAGNOSIS_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diagram.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM ', 'ALL',a.table_name, 'DIAGRAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM ','ALL',a.table_name, 'DIAGRAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\diagram_detail.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_DETAIL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_DETAIL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM_DETAIL ', 'ALL',a.table_name, 'DIAGRAM_DETAIL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM_DETAIL ','ALL',a.table_name, 'DIAGRAM_DETAIL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diagram_detail_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_DETAIL_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_DETAIL_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM_DETAIL_NOTES ', 'ALL',a.table_name, 'DIAGRAM_DETAIL_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM_DETAIL_NOTES ','ALL',a.table_name, 'DIAGRAM_DETAIL_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\diagram_image.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_IMAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_IMAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM_IMAGE ', 'ALL',a.table_name, 'DIAGRAM_IMAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM_IMAGE ','ALL',a.table_name, 'DIAGRAM_IMAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diagram_lay_imag.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_LAY_IMAG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_LAY_IMAG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM_LAY_IMAG ', 'ALL',a.table_name, 'DIAGRAM_LAY_IMAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM_LAY_IMAG ','ALL',a.table_name, 'DIAGRAM_LAY_IMAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\diagram_layout.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_LAYOUT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_LAYOUT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM_LAYOUT ', 'ALL',a.table_name, 'DIAGRAM_LAYOUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM_LAYOUT ','ALL',a.table_name, 'DIAGRAM_LAYOUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diagram_tools.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_TOOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_TOOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM_TOOLS ', 'ALL',a.table_name, 'DIAGRAM_TOOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM_TOOLS ','ALL',a.table_name, 'DIAGRAM_TOOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diagram_tools_group.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_TOOLS_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIAGRAM_TOOLS_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIAGRAM_TOOLS_GROUP ', 'ALL',a.table_name, 'DIAGRAM_TOOLS_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIAGRAM_TOOLS_GROUP ','ALL',a.table_name, 'DIAGRAM_TOOLS_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diet.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIET ', 'ALL',a.table_name, 'DIET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIET ','ALL',a.table_name, 'DIET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dietary_drug.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIETARY_DRUG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIETARY_DRUG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIETARY_DRUG ', 'ALL',a.table_name, 'DIETARY_DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIETARY_DRUG ','ALL',a.table_name, 'DIETARY_DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\diet_schedule.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIET_SCHEDULE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIET_SCHEDULE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIET_SCHEDULE ', 'ALL',a.table_name, 'DIET_SCHEDULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIET_SCHEDULE ','ALL',a.table_name, 'DIET_SCHEDULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dimension.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DIMENSION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DIMENSION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DIMENSION ', 'ALL',a.table_name, 'DIMENSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DIMENSION ','ALL',a.table_name, 'DIMENSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\discharge.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCHARGE ', 'ALL',a.table_name, 'DISCHARGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCHARGE ','ALL',a.table_name, 'DISCHARGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\discharge_dest.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_DEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_DEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCHARGE_DEST ', 'ALL',a.table_name, 'DISCHARGE_DEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCHARGE_DEST ','ALL',a.table_name, 'DISCHARGE_DEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\discharge_detail.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_DETAIL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_DETAIL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCHARGE_DETAIL ', 'ALL',a.table_name, 'DISCHARGE_DETAIL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCHARGE_DETAIL ','ALL',a.table_name, 'DISCHARGE_DETAIL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\discharge_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCHARGE_NOTES ', 'ALL',a.table_name, 'DISCHARGE_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCHARGE_NOTES ','ALL',a.table_name, 'DISCHARGE_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\discharge_reason.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_REASON','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCHARGE_REASON','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCHARGE_REASON ', 'ALL',a.table_name, 'DISCHARGE_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCHARGE_REASON ','ALL',a.table_name, 'DISCHARGE_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\disc_help.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISC_HELP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISC_HELP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISC_HELP ', 'ALL',a.table_name, 'DISC_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISC_HELP ','ALL',a.table_name, 'DISC_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\disch_prep_mesg.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCH_PREP_MESG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCH_PREP_MESG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCH_PREP_MESG ', 'ALL',a.table_name, 'DISCH_PREP_MESG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCH_PREP_MESG ','ALL',a.table_name, 'DISCH_PREP_MESG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\disch_reas_dest.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCH_REAS_DEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCH_REAS_DEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCH_REAS_DEST ', 'ALL',a.table_name, 'DISCH_REAS_DEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCH_REAS_DEST ','ALL',a.table_name, 'DISCH_REAS_DEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\disch_rea_transp_ent_inst.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCH_REA_TRANSP_ENT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCH_REA_TRANSP_ENT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCH_REA_TRANSP_ENT_INST ', 'ALL',a.table_name, 'DISCH_REA_TRANSP_ENT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCH_REA_TRANSP_ENT_INST ','ALL',a.table_name, 'DISCH_REA_TRANSP_ENT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\discriminator.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCRIMINATOR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCRIMINATOR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCRIMINATOR ', 'ALL',a.table_name, 'DISCRIMINATOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCRIMINATOR ','ALL',a.table_name, 'DISCRIMINATOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\discriminator_help.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISCRIMINATOR_HELP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISCRIMINATOR_HELP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISCRIMINATOR_HELP ', 'ALL',a.table_name, 'DISCRIMINATOR_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISCRIMINATOR_HELP ','ALL',a.table_name, 'DISCRIMINATOR_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\disc_vs_valid.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISC_VS_VALID','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISC_VS_VALID','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISC_VS_VALID ', 'ALL',a.table_name, 'DISC_VS_VALID') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISC_VS_VALID ','ALL',a.table_name, 'DISC_VS_VALID') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\district.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DISTRICT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DISTRICT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DISTRICT ', 'ALL',a.table_name, 'DISTRICT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DISTRICT ','ALL',a.table_name, 'DISTRICT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_action_criteria.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ACTION_CRITERIA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ACTION_CRITERIA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ACTION_CRITERIA ', 'ALL',a.table_name, 'DOC_ACTION_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ACTION_CRITERIA ','ALL',a.table_name, 'DOC_ACTION_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_area.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_AREA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_AREA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_AREA ', 'ALL',a.table_name, 'DOC_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_AREA ','ALL',a.table_name, 'DOC_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\doc_component.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_COMPONENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_COMPONENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_COMPONENT ', 'ALL',a.table_name, 'DOC_COMPONENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_COMPONENT ','ALL',a.table_name, 'DOC_COMPONENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_criteria.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_CRITERIA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_CRITERIA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_CRITERIA ', 'ALL',a.table_name, 'DOC_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_CRITERIA ','ALL',a.table_name, 'DOC_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\doc_destination.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_DESTINATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_DESTINATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_DESTINATION ', 'ALL',a.table_name, 'DOC_DESTINATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_DESTINATION ','ALL',a.table_name, 'DOC_DESTINATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_dimension.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_DIMENSION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_DIMENSION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_DIMENSION ', 'ALL',a.table_name, 'DOC_DIMENSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_DIMENSION ','ALL',a.table_name, 'DOC_DIMENSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\doc_element.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ELEMENT ', 'ALL',a.table_name, 'DOC_ELEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ELEMENT ','ALL',a.table_name, 'DOC_ELEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_element_crit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ELEMENT_CRIT ', 'ALL',a.table_name, 'DOC_ELEMENT_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ELEMENT_CRIT ','ALL',a.table_name, 'DOC_ELEMENT_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_element_qualif.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_QUALIF','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_QUALIF','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ELEMENT_QUALIF ', 'ALL',a.table_name, 'DOC_ELEMENT_QUALIF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ELEMENT_QUALIF ','ALL',a.table_name, 'DOC_ELEMENT_QUALIF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_element_quantif.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_QUANTIF','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_QUANTIF','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ELEMENT_QUANTIF ', 'ALL',a.table_name, 'DOC_ELEMENT_QUANTIF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ELEMENT_QUANTIF ','ALL',a.table_name, 'DOC_ELEMENT_QUANTIF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_element_rel.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_REL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ELEMENT_REL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ELEMENT_REL ', 'ALL',a.table_name, 'DOC_ELEMENT_REL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ELEMENT_REL ','ALL',a.table_name, 'DOC_ELEMENT_REL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_external.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_EXTERNAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_EXTERNAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_EXTERNAL ', 'ALL',a.table_name, 'DOC_EXTERNAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_EXTERNAL ','ALL',a.table_name, 'DOC_EXTERNAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_image.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_IMAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_IMAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_IMAGE ', 'ALL',a.table_name, 'DOC_IMAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_IMAGE ','ALL',a.table_name, 'DOC_IMAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_original.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ORIGINAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ORIGINAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ORIGINAL ', 'ALL',a.table_name, 'DOC_ORIGINAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ORIGINAL ','ALL',a.table_name, 'DOC_ORIGINAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_ori_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ORI_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_ORI_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_ORI_TYPE ', 'ALL',a.table_name, 'DOC_ORI_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_ORI_TYPE ','ALL',a.table_name, 'DOC_ORI_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\doc_qualification.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_QUALIFICATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_QUALIFICATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_QUALIFICATION ', 'ALL',a.table_name, 'DOC_QUALIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_QUALIFICATION ','ALL',a.table_name, 'DOC_QUALIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_quantification.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_QUANTIFICATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_QUANTIFICATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_QUANTIFICATION ', 'ALL',a.table_name, 'DOC_QUANTIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_QUANTIFICATION ','ALL',a.table_name, 'DOC_QUANTIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\doc_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_TEMPLATE ', 'ALL',a.table_name, 'DOC_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_TEMPLATE ','ALL',a.table_name, 'DOC_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_template_diagnosis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TEMPLATE_DIAGNOSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TEMPLATE_DIAGNOSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_TEMPLATE_DIAGNOSIS ', 'ALL',a.table_name, 'DOC_TEMPLATE_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_TEMPLATE_DIAGNOSIS ','ALL',a.table_name, 'DOC_TEMPLATE_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\doc_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_TYPE ', 'ALL',a.table_name, 'DOC_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_TYPE ','ALL',a.table_name, 'DOC_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\doc_type_soft.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TYPE_SOFT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOC_TYPE_SOFT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOC_TYPE_SOFT ', 'ALL',a.table_name, 'DOC_TYPE_SOFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOC_TYPE_SOFT ','ALL',a.table_name, 'DOC_TYPE_SOFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\document_area.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENT_AREA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENT_AREA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOCUMENT_AREA ', 'ALL',a.table_name, 'DOCUMENT_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOCUMENT_AREA ','ALL',a.table_name, 'DOCUMENT_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\documentation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENTATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENTATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOCUMENTATION ', 'ALL',a.table_name, 'DOCUMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOCUMENTATION ','ALL',a.table_name, 'DOCUMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\documentation_rel.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENTATION_REL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENTATION_REL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOCUMENTATION_REL ', 'ALL',a.table_name, 'DOCUMENTATION_REL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOCUMENTATION_REL ','ALL',a.table_name, 'DOCUMENTATION_REL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\documentation_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENTATION_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENTATION_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOCUMENTATION_TYPE ', 'ALL',a.table_name, 'DOCUMENTATION_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOCUMENTATION_TYPE ','ALL',a.table_name, 'DOCUMENTATION_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\document_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENT_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DOCUMENT_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DOCUMENT_TYPE ', 'ALL',a.table_name, 'DOCUMENT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DOCUMENT_TYPE ','ALL',a.table_name, 'DOCUMENT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG ', 'ALL',a.table_name, 'DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG ','ALL',a.table_name, 'DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_BCK ', 'ALL',a.table_name, 'DRUG_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_BCK ','ALL',a.table_name, 'DRUG_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\drug_bolus.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_BOLUS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_BOLUS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_BOLUS ', 'ALL',a.table_name, 'DRUG_BOLUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_BOLUS ','ALL',a.table_name, 'DRUG_BOLUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_brand.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_BRAND','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_BRAND','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_BRAND ', 'ALL',a.table_name, 'DRUG_BRAND') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_BRAND ','ALL',a.table_name, 'DRUG_BRAND') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\drug_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_DEP_CLIN_SERV ', 'ALL',a.table_name, 'DRUG_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_DEP_CLIN_SERV ','ALL',a.table_name, 'DRUG_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_despachos.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DESPACHOS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DESPACHOS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_DESPACHOS ', 'ALL',a.table_name, 'DRUG_DESPACHOS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_DESPACHOS ','ALL',a.table_name, 'DRUG_DESPACHOS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\drug_despachos_soft_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DESPACHOS_SOFT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DESPACHOS_SOFT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_DESPACHOS_SOFT_INST ', 'ALL',a.table_name, 'DRUG_DESPACHOS_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_DESPACHOS_SOFT_INST ','ALL',a.table_name, 'DRUG_DESPACHOS_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_drip.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DRIP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_DRIP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_DRIP ', 'ALL',a.table_name, 'DRUG_DRIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_DRIP ','ALL',a.table_name, 'DRUG_DRIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_form.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_FORM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_FORM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_FORM ', 'ALL',a.table_name, 'DRUG_FORM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_FORM ','ALL',a.table_name, 'DRUG_FORM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_instit_justification.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_INSTIT_JUSTIFICATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_INSTIT_JUSTIFICATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_INSTIT_JUSTIFICATION ', 'ALL',a.table_name, 'DRUG_INSTIT_JUSTIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_INSTIT_JUSTIFICATION ','ALL',a.table_name, 'DRUG_INSTIT_JUSTIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_justification.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_JUSTIFICATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_JUSTIFICATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_JUSTIFICATION ', 'ALL',a.table_name, 'DRUG_JUSTIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_JUSTIFICATION ','ALL',a.table_name, 'DRUG_JUSTIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_pharma.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PHARMA ', 'ALL',a.table_name, 'DRUG_PHARMA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PHARMA ','ALL',a.table_name, 'DRUG_PHARMA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_pharma_class.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA_CLASS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA_CLASS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PHARMA_CLASS ', 'ALL',a.table_name, 'DRUG_PHARMA_CLASS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PHARMA_CLASS ','ALL',a.table_name, 'DRUG_PHARMA_CLASS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_pharma_class_link.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA_CLASS_LINK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA_CLASS_LINK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PHARMA_CLASS_LINK ', 'ALL',a.table_name, 'DRUG_PHARMA_CLASS_LINK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PHARMA_CLASS_LINK ','ALL',a.table_name, 'DRUG_PHARMA_CLASS_LINK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_pharma_interaction.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA_INTERACTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PHARMA_INTERACTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PHARMA_INTERACTION ', 'ALL',a.table_name, 'DRUG_PHARMA_INTERACTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PHARMA_INTERACTION ','ALL',a.table_name, 'DRUG_PHARMA_INTERACTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\drug_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PLAN ', 'ALL',a.table_name, 'DRUG_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PLAN ','ALL',a.table_name, 'DRUG_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_presc_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PRESC_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PRESC_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PRESC_DET ', 'ALL',a.table_name, 'DRUG_PRESC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PRESC_DET ','ALL',a.table_name, 'DRUG_PRESC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\drug_presc_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PRESC_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PRESC_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PRESC_PLAN ', 'ALL',a.table_name, 'DRUG_PRESC_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PRESC_PLAN ','ALL',a.table_name, 'DRUG_PRESC_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_prescription.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PRESCRIPTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PRESCRIPTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PRESCRIPTION ', 'ALL',a.table_name, 'DRUG_PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PRESCRIPTION ','ALL',a.table_name, 'DRUG_PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\drug_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_PROTOCOLS ', 'ALL',a.table_name, 'DRUG_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_PROTOCOLS ','ALL',a.table_name, 'DRUG_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_REQ ', 'ALL',a.table_name, 'DRUG_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_REQ ','ALL',a.table_name, 'DRUG_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_req_det.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_REQ_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_REQ_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_REQ_DET ', 'ALL',a.table_name, 'DRUG_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_REQ_DET ','ALL',a.table_name, 'DRUG_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_req_supply.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_REQ_SUPPLY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_REQ_SUPPLY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_REQ_SUPPLY ', 'ALL',a.table_name, 'DRUG_REQ_SUPPLY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_REQ_SUPPLY ','ALL',a.table_name, 'DRUG_REQ_SUPPLY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_route.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_ROUTE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_ROUTE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_ROUTE ', 'ALL',a.table_name, 'DRUG_ROUTE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_ROUTE ','ALL',a.table_name, 'DRUG_ROUTE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_take_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_TAKE_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_TAKE_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_TAKE_PLAN ', 'ALL',a.table_name, 'DRUG_TAKE_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_TAKE_PLAN ','ALL',a.table_name, 'DRUG_TAKE_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\drug_take_time.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_TAKE_TIME','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DRUG_TAKE_TIME','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DRUG_TAKE_TIME ', 'ALL',a.table_name, 'DRUG_TAKE_TIME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DRUG_TAKE_TIME ','ALL',a.table_name, 'DRUG_TAKE_TIME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\element_rel.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ELEMENT_REL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ELEMENT_REL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ELEMENT_REL ', 'ALL',a.table_name, 'ELEMENT_REL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ELEMENT_REL ','ALL',a.table_name, 'ELEMENT_REL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\emb_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EMB_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EMB_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EMB_DEP_CLIN_SERV ', 'ALL',a.table_name, 'EMB_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EMB_DEP_CLIN_SERV ','ALL',a.table_name, 'EMB_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\epis_anamnesis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_ANAMNESIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_ANAMNESIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_ANAMNESIS ', 'ALL',a.table_name, 'EPIS_ANAMNESIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_ANAMNESIS ','ALL',a.table_name, 'EPIS_ANAMNESIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_attending_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_ATTENDING_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_ATTENDING_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_ATTENDING_NOTES ', 'ALL',a.table_name, 'EPIS_ATTENDING_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_ATTENDING_NOTES ','ALL',a.table_name, 'EPIS_ATTENDING_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_bartchart.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BARTCHART','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BARTCHART','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_BARTCHART ', 'ALL',a.table_name, 'EPIS_BARTCHART') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_BARTCHART ','ALL',a.table_name, 'EPIS_BARTCHART') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_bartchart_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BARTCHART_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BARTCHART_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_BARTCHART_DET ', 'ALL',a.table_name, 'EPIS_BARTCHART_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_BARTCHART_DET ','ALL',a.table_name, 'EPIS_BARTCHART_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_body_painting.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BODY_PAINTING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BODY_PAINTING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_BODY_PAINTING ', 'ALL',a.table_name, 'EPIS_BODY_PAINTING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_BODY_PAINTING ','ALL',a.table_name, 'EPIS_BODY_PAINTING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_body_painting_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BODY_PAINTING_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_BODY_PAINTING_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_BODY_PAINTING_DET ', 'ALL',a.table_name, 'EPIS_BODY_PAINTING_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_BODY_PAINTING_DET ','ALL',a.table_name, 'EPIS_BODY_PAINTING_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_complaint.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_COMPLAINT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_COMPLAINT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_COMPLAINT ', 'ALL',a.table_name, 'EPIS_COMPLAINT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_COMPLAINT ','ALL',a.table_name, 'EPIS_COMPLAINT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_diagnosis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIAGNOSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIAGNOSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_DIAGNOSIS ', 'ALL',a.table_name, 'EPIS_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_DIAGNOSIS ','ALL',a.table_name, 'EPIS_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_diagnosis_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIAGNOSIS_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIAGNOSIS_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_DIAGNOSIS_HIST ', 'ALL',a.table_name, 'EPIS_DIAGNOSIS_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_DIAGNOSIS_HIST ','ALL',a.table_name, 'EPIS_DIAGNOSIS_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_diagnosis_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIAGNOSIS_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIAGNOSIS_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_DIAGNOSIS_NOTES ', 'ALL',a.table_name, 'EPIS_DIAGNOSIS_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_DIAGNOSIS_NOTES ','ALL',a.table_name, 'EPIS_DIAGNOSIS_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_diet.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DIET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_DIET ', 'ALL',a.table_name, 'EPIS_DIET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_DIET ','ALL',a.table_name, 'EPIS_DIET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_documentation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DOCUMENTATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DOCUMENTATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_DOCUMENTATION ', 'ALL',a.table_name, 'EPIS_DOCUMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_DOCUMENTATION ','ALL',a.table_name, 'EPIS_DOCUMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_documentation_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DOCUMENTATION_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DOCUMENTATION_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_DOCUMENTATION_DET ', 'ALL',a.table_name, 'EPIS_DOCUMENTATION_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_DOCUMENTATION_DET ','ALL',a.table_name, 'EPIS_DOCUMENTATION_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\epis_drug_usage.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DRUG_USAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_DRUG_USAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_DRUG_USAGE ', 'ALL',a.table_name, 'EPIS_DRUG_USAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_DRUG_USAGE ','ALL',a.table_name, 'EPIS_DRUG_USAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_EXT_SYS ', 'ALL',a.table_name, 'EPIS_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_EXT_SYS ','ALL',a.table_name, 'EPIS_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_health_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HEALTH_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HEALTH_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_HEALTH_PLAN ', 'ALL',a.table_name, 'EPIS_HEALTH_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_HEALTH_PLAN ','ALL',a.table_name, 'EPIS_HEALTH_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_hidrics.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HIDRICS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HIDRICS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_HIDRICS ', 'ALL',a.table_name, 'EPIS_HIDRICS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_HIDRICS ','ALL',a.table_name, 'EPIS_HIDRICS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_hidrics_balance.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HIDRICS_BALANCE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HIDRICS_BALANCE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_HIDRICS_BALANCE ', 'ALL',a.table_name, 'EPIS_HIDRICS_BALANCE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_HIDRICS_BALANCE ','ALL',a.table_name, 'EPIS_HIDRICS_BALANCE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_hidrics_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HIDRICS_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_HIDRICS_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_HIDRICS_DET ', 'ALL',a.table_name, 'EPIS_HIDRICS_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_HIDRICS_DET ','ALL',a.table_name, 'EPIS_HIDRICS_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_info.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INFO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INFO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_INFO ', 'ALL',a.table_name, 'EPIS_INFO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_INFO ','ALL',a.table_name, 'EPIS_INFO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_institution.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INSTITUTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INSTITUTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_INSTITUTION ', 'ALL',a.table_name, 'EPIS_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_INSTITUTION ','ALL',a.table_name, 'EPIS_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_interv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INTERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INTERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_INTERV ', 'ALL',a.table_name, 'EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_INTERV ','ALL',a.table_name, 'EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_interval_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INTERVAL_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_INTERVAL_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_INTERVAL_NOTES ', 'ALL',a.table_name, 'EPIS_INTERVAL_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_INTERVAL_NOTES ','ALL',a.table_name, 'EPIS_INTERVAL_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_man.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_MAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_MAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_MAN ', 'ALL',a.table_name, 'EPIS_MAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_MAN ','ALL',a.table_name, 'EPIS_MAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_observation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_OBSERVATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_OBSERVATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_OBSERVATION ', 'ALL',a.table_name, 'EPIS_OBSERVATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_OBSERVATION ','ALL',a.table_name, 'EPIS_OBSERVATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_obs_exam.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_OBS_EXAM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_OBS_EXAM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_OBS_EXAM ', 'ALL',a.table_name, 'EPIS_OBS_EXAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_OBS_EXAM ','ALL',a.table_name, 'EPIS_OBS_EXAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\epis_obs_photo.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_OBS_PHOTO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_OBS_PHOTO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_OBS_PHOTO ', 'ALL',a.table_name, 'EPIS_OBS_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_OBS_PHOTO ','ALL',a.table_name, 'EPIS_OBS_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\episode.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPISODE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPISODE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPISODE ', 'ALL',a.table_name, 'EPISODE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPISODE ','ALL',a.table_name, 'EPISODE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_photo.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PHOTO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PHOTO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_PHOTO ', 'ALL',a.table_name, 'EPIS_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_PHOTO ','ALL',a.table_name, 'EPIS_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_positioning.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_POSITIONING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_POSITIONING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_POSITIONING ', 'ALL',a.table_name, 'EPIS_POSITIONING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_POSITIONING ','ALL',a.table_name, 'EPIS_POSITIONING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_positioning_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_POSITIONING_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_POSITIONING_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_POSITIONING_DET ', 'ALL',a.table_name, 'EPIS_POSITIONING_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_POSITIONING_DET ','ALL',a.table_name, 'EPIS_POSITIONING_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_positioning_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_POSITIONING_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_POSITIONING_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_POSITIONING_PLAN ', 'ALL',a.table_name, 'EPIS_POSITIONING_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_POSITIONING_PLAN ','ALL',a.table_name, 'EPIS_POSITIONING_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_pregnancy.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PREGNANCY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PREGNANCY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_PREGNANCY ', 'ALL',a.table_name, 'EPIS_PREGNANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_PREGNANCY ','ALL',a.table_name, 'EPIS_PREGNANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_problem.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROBLEM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROBLEM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_PROBLEM ', 'ALL',a.table_name, 'EPIS_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_PROBLEM ','ALL',a.table_name, 'EPIS_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_prof_rec.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROF_REC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROF_REC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_PROF_REC ', 'ALL',a.table_name, 'EPIS_PROF_REC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_PROF_REC ','ALL',a.table_name, 'EPIS_PROF_REC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_prof_resp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROF_RESP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROF_RESP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_PROF_RESP ', 'ALL',a.table_name, 'EPIS_PROF_RESP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_PROF_RESP ','ALL',a.table_name, 'EPIS_PROF_RESP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_PROTOCOLS ', 'ALL',a.table_name, 'EPIS_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_PROTOCOLS ','ALL',a.table_name, 'EPIS_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_readmission.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_READMISSION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_READMISSION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_READMISSION ', 'ALL',a.table_name, 'EPIS_READMISSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_READMISSION ','ALL',a.table_name, 'EPIS_READMISSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_recomend.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_RECOMEND','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_RECOMEND','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_RECOMEND ', 'ALL',a.table_name, 'EPIS_RECOMEND') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_RECOMEND ','ALL',a.table_name, 'EPIS_RECOMEND') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\epis_report.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_REPORT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_REPORT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_REPORT ', 'ALL',a.table_name, 'EPIS_REPORT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_REPORT ','ALL',a.table_name, 'EPIS_REPORT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_report_section.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_REPORT_SECTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_REPORT_SECTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_REPORT_SECTION ', 'ALL',a.table_name, 'EPIS_REPORT_SECTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_REPORT_SECTION ','ALL',a.table_name, 'EPIS_REPORT_SECTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_review_systems.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_REVIEW_SYSTEMS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_REVIEW_SYSTEMS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_REVIEW_SYSTEMS ', 'ALL',a.table_name, 'EPIS_REVIEW_SYSTEMS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_REVIEW_SYSTEMS ','ALL',a.table_name, 'EPIS_REVIEW_SYSTEMS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_task.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TASK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TASK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_TASK ', 'ALL',a.table_name, 'EPIS_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_TASK ','ALL',a.table_name, 'EPIS_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\epis_triage.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TRIAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TRIAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_TRIAGE ', 'ALL',a.table_name, 'EPIS_TRIAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_TRIAGE ','ALL',a.table_name, 'EPIS_TRIAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_TYPE ', 'ALL',a.table_name, 'EPIS_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_TYPE ','ALL',a.table_name, 'EPIS_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\epis_type_room.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TYPE_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EPIS_TYPE_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EPIS_TYPE_ROOM ', 'ALL',a.table_name, 'EPIS_TYPE_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EPIS_TYPE_ROOM ','ALL',a.table_name, 'EPIS_TYPE_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\equip_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EQUIP_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EQUIP_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EQUIP_PROTOCOLS ', 'ALL',a.table_name, 'EQUIP_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EQUIP_PROTOCOLS ','ALL',a.table_name, 'EQUIP_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\error.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ERROR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ERROR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ERROR ', 'ALL',a.table_name, 'ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ERROR ','ALL',a.table_name, 'ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\error_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ERROR_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ERROR_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ERROR_HIST ', 'ALL',a.table_name, 'ERROR_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ERROR_HIST ','ALL',a.table_name, 'ERROR_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\estate.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ESTATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ESTATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ESTATE ', 'ALL',a.table_name, 'ESTATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ESTATE ','ALL',a.table_name, 'ESTATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\event.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EVENT ', 'ALL',a.table_name, 'EVENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EVENT ','ALL',a.table_name, 'EVENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\event_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EVENT_GROUP ', 'ALL',a.table_name, 'EVENT_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EVENT_GROUP ','ALL',a.table_name, 'EVENT_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\event_group_soft_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_GROUP_SOFT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_GROUP_SOFT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EVENT_GROUP_SOFT_INST ', 'ALL',a.table_name, 'EVENT_GROUP_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EVENT_GROUP_SOFT_INST ','ALL',a.table_name, 'EVENT_GROUP_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\event_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EVENT_HIST ', 'ALL',a.table_name, 'EVENT_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EVENT_HIST ','ALL',a.table_name, 'EVENT_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\event_most_freq.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_MOST_FREQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EVENT_MOST_FREQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EVENT_MOST_FREQ ', 'ALL',a.table_name, 'EVENT_MOST_FREQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EVENT_MOST_FREQ ','ALL',a.table_name, 'EVENT_MOST_FREQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM ', 'ALL',a.table_name, 'EXAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM ','ALL',a.table_name, 'EXAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\exam_cat.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_CAT ', 'ALL',a.table_name, 'EXAM_CAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_CAT ','ALL',a.table_name, 'EXAM_CAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_cat_dcs.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT_DCS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT_DCS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_CAT_DCS ', 'ALL',a.table_name, 'EXAM_CAT_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_CAT_DCS ','ALL',a.table_name, 'EXAM_CAT_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_cat_dcs_bck1.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT_DCS_BCK1','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT_DCS_BCK1','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_CAT_DCS_BCK1 ', 'ALL',a.table_name, 'EXAM_CAT_DCS_BCK1') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_CAT_DCS_BCK1 ','ALL',a.table_name, 'EXAM_CAT_DCS_BCK1') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_cat_dcs_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT_DCS_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_CAT_DCS_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_CAT_DCS_EXT_SYS ', 'ALL',a.table_name, 'EXAM_CAT_DCS_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_CAT_DCS_EXT_SYS ','ALL',a.table_name, 'EXAM_CAT_DCS_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_DEP_CLIN_SERV ', 'ALL',a.table_name, 'EXAM_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_DEP_CLIN_SERV ','ALL',a.table_name, 'EXAM_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_drug.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_DRUG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_DRUG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_DRUG ', 'ALL',a.table_name, 'EXAM_DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_DRUG ','ALL',a.table_name, 'EXAM_DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_egp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_EGP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_EGP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_EGP ', 'ALL',a.table_name, 'EXAM_EGP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_EGP ','ALL',a.table_name, 'EXAM_EGP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_ext_sys_delete.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_EXT_SYS_DELETE ', 'ALL',a.table_name, 'EXAM_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_EXT_SYS_DELETE ','ALL',a.table_name, 'EXAM_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_GROUP ', 'ALL',a.table_name, 'EXAM_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_GROUP ','ALL',a.table_name, 'EXAM_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\exam_prep_mesg.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_PREP_MESG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_PREP_MESG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_PREP_MESG ', 'ALL',a.table_name, 'EXAM_PREP_MESG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_PREP_MESG ','ALL',a.table_name, 'EXAM_PREP_MESG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_PROTOCOLS ', 'ALL',a.table_name, 'EXAM_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_PROTOCOLS ','ALL',a.table_name, 'EXAM_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\exam_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_REQ ', 'ALL',a.table_name, 'EXAM_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_REQ ','ALL',a.table_name, 'EXAM_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_req_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_REQ_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_REQ_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_REQ_DET ', 'ALL',a.table_name, 'EXAM_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_REQ_DET ','ALL',a.table_name, 'EXAM_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\exam_result.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_RESULT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_RESULT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_RESULT ', 'ALL',a.table_name, 'EXAM_RESULT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_RESULT ','ALL',a.table_name, 'EXAM_RESULT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\exam_room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXAM_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXAM_ROOM ', 'ALL',a.table_name, 'EXAM_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXAM_ROOM ','ALL',a.table_name, 'EXAM_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\external_cause.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXTERNAL_CAUSE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXTERNAL_CAUSE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXTERNAL_CAUSE ', 'ALL',a.table_name, 'EXTERNAL_CAUSE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXTERNAL_CAUSE ','ALL',a.table_name, 'EXTERNAL_CAUSE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\external_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','EXTERNAL_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','EXTERNAL_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('EXTERNAL_SYS ', 'ALL',a.table_name, 'EXTERNAL_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('EXTERNAL_SYS ','ALL',a.table_name, 'EXTERNAL_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\family_monetary.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','FAMILY_MONETARY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','FAMILY_MONETARY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('FAMILY_MONETARY ', 'ALL',a.table_name, 'FAMILY_MONETARY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('FAMILY_MONETARY ','ALL',a.table_name, 'FAMILY_MONETARY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\family_relationship.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','FAMILY_RELATIONSHIP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','FAMILY_RELATIONSHIP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('FAMILY_RELATIONSHIP ', 'ALL',a.table_name, 'FAMILY_RELATIONSHIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('FAMILY_RELATIONSHIP ','ALL',a.table_name, 'FAMILY_RELATIONSHIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\family_relationship_relat.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','FAMILY_RELATIONSHIP_RELAT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','FAMILY_RELATIONSHIP_RELAT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('FAMILY_RELATIONSHIP_RELAT ', 'ALL',a.table_name, 'FAMILY_RELATIONSHIP_RELAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('FAMILY_RELATIONSHIP_RELAT ','ALL',a.table_name, 'FAMILY_RELATIONSHIP_RELAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\floors.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('FLOORS ', 'ALL',a.table_name, 'FLOORS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('FLOORS ','ALL',a.table_name, 'FLOORS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\floors_department.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS_DEPARTMENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS_DEPARTMENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('FLOORS_DEPARTMENT ', 'ALL',a.table_name, 'FLOORS_DEPARTMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('FLOORS_DEPARTMENT ','ALL',a.table_name, 'FLOORS_DEPARTMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\floors_dep_position.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS_DEP_POSITION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS_DEP_POSITION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('FLOORS_DEP_POSITION ', 'ALL',a.table_name, 'FLOORS_DEP_POSITION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('FLOORS_DEP_POSITION ','ALL',a.table_name, 'FLOORS_DEP_POSITION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\floors_institution.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS_INSTITUTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','FLOORS_INSTITUTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('FLOORS_INSTITUTION ', 'ALL',a.table_name, 'FLOORS_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('FLOORS_INSTITUTION ','ALL',a.table_name, 'FLOORS_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\geo_location.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','GEO_LOCATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','GEO_LOCATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('GEO_LOCATION ', 'ALL',a.table_name, 'GEO_LOCATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('GEO_LOCATION ','ALL',a.table_name, 'GEO_LOCATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\ginec_obstet.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','GINEC_OBSTET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','GINEC_OBSTET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('GINEC_OBSTET ', 'ALL',a.table_name, 'GINEC_OBSTET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('GINEC_OBSTET ','ALL',a.table_name, 'GINEC_OBSTET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\graffar_criteria.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','GRAFFAR_CRITERIA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','GRAFFAR_CRITERIA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('GRAFFAR_CRITERIA ', 'ALL',a.table_name, 'GRAFFAR_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('GRAFFAR_CRITERIA ','ALL',a.table_name, 'GRAFFAR_CRITERIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\graffar_crit_value.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','GRAFFAR_CRIT_VALUE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','GRAFFAR_CRIT_VALUE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('GRAFFAR_CRIT_VALUE ', 'ALL',a.table_name, 'GRAFFAR_CRIT_VALUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('GRAFFAR_CRIT_VALUE ','ALL',a.table_name, 'GRAFFAR_CRIT_VALUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\grid_task.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','GRID_TASK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','GRID_TASK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('GRID_TASK ', 'ALL',a.table_name, 'GRID_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('GRID_TASK ','ALL',a.table_name, 'GRID_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\grid_task_between.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','GRID_TASK_BETWEEN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','GRID_TASK_BETWEEN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('GRID_TASK_BETWEEN ', 'ALL',a.table_name, 'GRID_TASK_BETWEEN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('GRID_TASK_BETWEEN ','ALL',a.table_name, 'GRID_TASK_BETWEEN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\habit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HABIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HABIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HABIT ', 'ALL',a.table_name, 'HABIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HABIT ','ALL',a.table_name, 'HABIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\harvest.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HARVEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HARVEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HARVEST ', 'ALL',a.table_name, 'HARVEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HARVEST ','ALL',a.table_name, 'HARVEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\hcn_def_crit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HCN_DEF_CRIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HCN_DEF_CRIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HCN_DEF_CRIT ', 'ALL',a.table_name, 'HCN_DEF_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HCN_DEF_CRIT ','ALL',a.table_name, 'HCN_DEF_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\health_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HEALTH_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HEALTH_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HEALTH_PLAN ', 'ALL',a.table_name, 'HEALTH_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HEALTH_PLAN ','ALL',a.table_name, 'HEALTH_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\health_plan_instit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HEALTH_PLAN_INSTIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HEALTH_PLAN_INSTIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HEALTH_PLAN_INSTIT ', 'ALL',a.table_name, 'HEALTH_PLAN_INSTIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HEALTH_PLAN_INSTIT ','ALL',a.table_name, 'HEALTH_PLAN_INSTIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\hemo_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HEMO_PROTOCOLS ', 'ALL',a.table_name, 'HEMO_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HEMO_PROTOCOLS ','ALL',a.table_name, 'HEMO_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\hemo_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HEMO_REQ ', 'ALL',a.table_name, 'HEMO_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HEMO_REQ ','ALL',a.table_name, 'HEMO_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\hemo_req_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_REQ_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_REQ_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HEMO_REQ_DET ', 'ALL',a.table_name, 'HEMO_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HEMO_REQ_DET ','ALL',a.table_name, 'HEMO_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\hemo_req_supply.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_REQ_SUPPLY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_REQ_SUPPLY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HEMO_REQ_SUPPLY ', 'ALL',a.table_name, 'HEMO_REQ_SUPPLY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HEMO_REQ_SUPPLY ','ALL',a.table_name, 'HEMO_REQ_SUPPLY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\hemo_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HEMO_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HEMO_TYPE ', 'ALL',a.table_name, 'HEMO_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HEMO_TYPE ','ALL',a.table_name, 'HEMO_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\hidrics.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HIDRICS ', 'ALL',a.table_name, 'HIDRICS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HIDRICS ','ALL',a.table_name, 'HIDRICS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\hidrics_interval.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS_INTERVAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS_INTERVAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HIDRICS_INTERVAL ', 'ALL',a.table_name, 'HIDRICS_INTERVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HIDRICS_INTERVAL ','ALL',a.table_name, 'HIDRICS_INTERVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\hidrics_relation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS_RELATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS_RELATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HIDRICS_RELATION ', 'ALL',a.table_name, 'HIDRICS_RELATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HIDRICS_RELATION ','ALL',a.table_name, 'HIDRICS_RELATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\hidrics_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HIDRICS_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HIDRICS_TYPE ', 'ALL',a.table_name, 'HIDRICS_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HIDRICS_TYPE ','ALL',a.table_name, 'HIDRICS_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\home.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','HOME','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','HOME','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('HOME ', 'ALL',a.table_name, 'HOME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('HOME ','ALL',a.table_name, 'HOME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_axis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_AXIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_AXIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_AXIS ', 'ALL',a.table_name, 'ICNP_AXIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_AXIS ','ALL',a.table_name, 'ICNP_AXIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_classification.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_CLASSIFICATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_CLASSIFICATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_CLASSIFICATION ', 'ALL',a.table_name, 'ICNP_CLASSIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_CLASSIFICATION ','ALL',a.table_name, 'ICNP_CLASSIFICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_compo_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPO_CLIN_SERV ', 'ALL',a.table_name, 'ICNP_COMPO_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPO_CLIN_SERV ','ALL',a.table_name, 'ICNP_COMPO_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\icnp_compo_dcs.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_DCS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_DCS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPO_DCS ', 'ALL',a.table_name, 'ICNP_COMPO_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPO_DCS ','ALL',a.table_name, 'ICNP_COMPO_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_compo_folder.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_FOLDER','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_FOLDER','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPO_FOLDER ', 'ALL',a.table_name, 'ICNP_COMPO_FOLDER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPO_FOLDER ','ALL',a.table_name, 'ICNP_COMPO_FOLDER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\icnp_compo_folder_060425.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_FOLDER_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_FOLDER_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPO_FOLDER_060425 ', 'ALL',a.table_name, 'ICNP_COMPO_FOLDER_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPO_FOLDER_060425 ','ALL',a.table_name, 'ICNP_COMPO_FOLDER_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_compo_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPO_INST ', 'ALL',a.table_name, 'ICNP_COMPO_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPO_INST ','ALL',a.table_name, 'ICNP_COMPO_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\icnp_compo_inst_060425.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_INST_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPO_INST_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPO_INST_060425 ', 'ALL',a.table_name, 'ICNP_COMPO_INST_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPO_INST_060425 ','ALL',a.table_name, 'ICNP_COMPO_INST_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_composition.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPOSITION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPOSITION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPOSITION ', 'ALL',a.table_name, 'ICNP_COMPOSITION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPOSITION ','ALL',a.table_name, 'ICNP_COMPOSITION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_composition_term.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPOSITION_TERM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPOSITION_TERM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPOSITION_TERM ', 'ALL',a.table_name, 'ICNP_COMPOSITION_TERM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPOSITION_TERM ','ALL',a.table_name, 'ICNP_COMPOSITION_TERM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_composition_060425.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPOSITION_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_COMPOSITION_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_COMPOSITION_060425 ', 'ALL',a.table_name, 'ICNP_COMPOSITION_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_COMPOSITION_060425 ','ALL',a.table_name, 'ICNP_COMPOSITION_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_dictionary.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_DICTIONARY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_DICTIONARY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_DICTIONARY ', 'ALL',a.table_name, 'ICNP_DICTIONARY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_DICTIONARY ','ALL',a.table_name, 'ICNP_DICTIONARY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_epis_diag_interv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAG_INTERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAG_INTERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_EPIS_DIAG_INTERV ', 'ALL',a.table_name, 'ICNP_EPIS_DIAG_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_EPIS_DIAG_INTERV ','ALL',a.table_name, 'ICNP_EPIS_DIAG_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_epis_diag_interv_060425.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAG_INTERV_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAG_INTERV_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_EPIS_DIAG_INTERV_060425 ', 'ALL',a.table_name, 'ICNP_EPIS_DIAG_INTERV_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_EPIS_DIAG_INTERV_060425 ','ALL',a.table_name, 'ICNP_EPIS_DIAG_INTERV_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_epis_diagnosis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAGNOSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAGNOSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_EPIS_DIAGNOSIS ', 'ALL',a.table_name, 'ICNP_EPIS_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_EPIS_DIAGNOSIS ','ALL',a.table_name, 'ICNP_EPIS_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_epis_diagnosis_060425.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAGNOSIS_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_DIAGNOSIS_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_EPIS_DIAGNOSIS_060425 ', 'ALL',a.table_name, 'ICNP_EPIS_DIAGNOSIS_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_EPIS_DIAGNOSIS_060425 ','ALL',a.table_name, 'ICNP_EPIS_DIAGNOSIS_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\icnp_epis_intervention.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_INTERVENTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_INTERVENTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_EPIS_INTERVENTION ', 'ALL',a.table_name, 'ICNP_EPIS_INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_EPIS_INTERVENTION ','ALL',a.table_name, 'ICNP_EPIS_INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_epis_intervention_060425.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_INTERVENTION_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_EPIS_INTERVENTION_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_EPIS_INTERVENTION_060425 ', 'ALL',a.table_name, 'ICNP_EPIS_INTERVENTION_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_EPIS_INTERVENTION_060425 ','ALL',a.table_name, 'ICNP_EPIS_INTERVENTION_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\icnp_folder.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_FOLDER','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_FOLDER','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_FOLDER ', 'ALL',a.table_name, 'ICNP_FOLDER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_FOLDER ','ALL',a.table_name, 'ICNP_FOLDER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_folder_060425.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_FOLDER_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_FOLDER_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_FOLDER_060425 ', 'ALL',a.table_name, 'ICNP_FOLDER_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_FOLDER_060425 ','ALL',a.table_name, 'ICNP_FOLDER_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\icnp_morph.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_MORPH','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_MORPH','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_MORPH ', 'ALL',a.table_name, 'ICNP_MORPH') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_MORPH ','ALL',a.table_name, 'ICNP_MORPH') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_predefined_action.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_PREDEFINED_ACTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_PREDEFINED_ACTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_PREDEFINED_ACTION ', 'ALL',a.table_name, 'ICNP_PREDEFINED_ACTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_PREDEFINED_ACTION ','ALL',a.table_name, 'ICNP_PREDEFINED_ACTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_predefined_action_060425.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_PREDEFINED_ACTION_060425','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_PREDEFINED_ACTION_060425','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_PREDEFINED_ACTION_060425 ', 'ALL',a.table_name, 'ICNP_PREDEFINED_ACTION_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_PREDEFINED_ACTION_060425 ','ALL',a.table_name, 'ICNP_PREDEFINED_ACTION_060425') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_relationship.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_RELATIONSHIP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_RELATIONSHIP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_RELATIONSHIP ', 'ALL',a.table_name, 'ICNP_RELATIONSHIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_RELATIONSHIP ','ALL',a.table_name, 'ICNP_RELATIONSHIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_term.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_TERM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_TERM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_TERM ', 'ALL',a.table_name, 'ICNP_TERM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_TERM ','ALL',a.table_name, 'ICNP_TERM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_transition_state.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_TRANSITION_STATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_TRANSITION_STATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_TRANSITION_STATE ', 'ALL',a.table_name, 'ICNP_TRANSITION_STATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_TRANSITION_STATE ','ALL',a.table_name, 'ICNP_TRANSITION_STATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\icnp_transition_state_060426.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_TRANSITION_STATE_060426','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ICNP_TRANSITION_STATE_060426','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ICNP_TRANSITION_STATE_060426 ', 'ALL',a.table_name, 'ICNP_TRANSITION_STATE_060426') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ICNP_TRANSITION_STATE_060426 ','ALL',a.table_name, 'ICNP_TRANSITION_STATE_060426') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\identification_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IDENTIFICATION_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IDENTIFICATION_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IDENTIFICATION_NOTES ', 'ALL',a.table_name, 'IDENTIFICATION_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IDENTIFICATION_NOTES ','ALL',a.table_name, 'IDENTIFICATION_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\implementation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IMPLEMENTATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IMPLEMENTATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IMPLEMENTATION ', 'ALL',a.table_name, 'IMPLEMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IMPLEMENTATION ','ALL',a.table_name, 'IMPLEMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\import_analysis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_ANALYSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_ANALYSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IMPORT_ANALYSIS ', 'ALL',a.table_name, 'IMPORT_ANALYSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IMPORT_ANALYSIS ','ALL',a.table_name, 'IMPORT_ANALYSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\import_mcdt.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_MCDT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_MCDT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IMPORT_MCDT ', 'ALL',a.table_name, 'IMPORT_MCDT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IMPORT_MCDT ','ALL',a.table_name, 'IMPORT_MCDT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\import_mcdt_migra.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_MCDT_MIGRA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_MCDT_MIGRA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IMPORT_MCDT_MIGRA ', 'ALL',a.table_name, 'IMPORT_MCDT_MIGRA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IMPORT_MCDT_MIGRA ','ALL',a.table_name, 'IMPORT_MCDT_MIGRA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\import_mcdt_20060303.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_MCDT_20060303','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_MCDT_20060303','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IMPORT_MCDT_20060303 ', 'ALL',a.table_name, 'IMPORT_MCDT_20060303') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IMPORT_MCDT_20060303 ','ALL',a.table_name, 'IMPORT_MCDT_20060303') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\import_prof_admin.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_PROF_ADMIN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_PROF_ADMIN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IMPORT_PROF_ADMIN ', 'ALL',a.table_name, 'IMPORT_PROF_ADMIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IMPORT_PROF_ADMIN ','ALL',a.table_name, 'IMPORT_PROF_ADMIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\import_prof_med.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_PROF_MED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','IMPORT_PROF_MED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('IMPORT_PROF_MED ', 'ALL',a.table_name, 'IMPORT_PROF_MED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('IMPORT_PROF_MED ','ALL',a.table_name, 'IMPORT_PROF_MED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\ine_location.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INE_LOCATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INE_LOCATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INE_LOCATION ', 'ALL',a.table_name, 'INE_LOCATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INE_LOCATION ','ALL',a.table_name, 'INE_LOCATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_atc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ATC ', 'ALL',a.table_name, 'INF_ATC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ATC ','ALL',a.table_name, 'INF_ATC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_atc_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ATC_BCK ', 'ALL',a.table_name, 'INF_ATC_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ATC_BCK ','ALL',a.table_name, 'INF_ATC_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_atc_lnk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_LNK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_LNK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ATC_LNK ', 'ALL',a.table_name, 'INF_ATC_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ATC_LNK ','ALL',a.table_name, 'INF_ATC_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_atc_lnk_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_LNK_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_LNK_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ATC_LNK_BCK ', 'ALL',a.table_name, 'INF_ATC_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ATC_LNK_BCK ','ALL',a.table_name, 'INF_ATC_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_atc_lnk_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_LNK_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_LNK_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ATC_LNK_NEW ', 'ALL',a.table_name, 'INF_ATC_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ATC_LNK_NEW ','ALL',a.table_name, 'INF_ATC_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_atc_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ATC_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ATC_NEW ', 'ALL',a.table_name, 'INF_ATC_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ATC_NEW ','ALL',a.table_name, 'INF_ATC_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\inf_cft.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CFT ', 'ALL',a.table_name, 'INF_CFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CFT ','ALL',a.table_name, 'INF_CFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_cft_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CFT_BCK ', 'ALL',a.table_name, 'INF_CFT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CFT_BCK ','ALL',a.table_name, 'INF_CFT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_cft_lnk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_LNK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_LNK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CFT_LNK ', 'ALL',a.table_name, 'INF_CFT_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CFT_LNK ','ALL',a.table_name, 'INF_CFT_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_cft_lnk_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_LNK_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_LNK_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CFT_LNK_BCK ', 'ALL',a.table_name, 'INF_CFT_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CFT_LNK_BCK ','ALL',a.table_name, 'INF_CFT_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_cft_lnk_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_LNK_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_LNK_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CFT_LNK_NEW ', 'ALL',a.table_name, 'INF_CFT_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CFT_LNK_NEW ','ALL',a.table_name, 'INF_CFT_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_cft_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CFT_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CFT_NEW ', 'ALL',a.table_name, 'INF_CFT_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CFT_NEW ','ALL',a.table_name, 'INF_CFT_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_class_disp.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_DISP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_DISP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CLASS_DISP ', 'ALL',a.table_name, 'INF_CLASS_DISP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CLASS_DISP ','ALL',a.table_name, 'INF_CLASS_DISP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_class_disp_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_DISP_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_DISP_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CLASS_DISP_BCK ', 'ALL',a.table_name, 'INF_CLASS_DISP_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CLASS_DISP_BCK ','ALL',a.table_name, 'INF_CLASS_DISP_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_class_disp_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_DISP_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_DISP_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CLASS_DISP_NEW ', 'ALL',a.table_name, 'INF_CLASS_DISP_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CLASS_DISP_NEW ','ALL',a.table_name, 'INF_CLASS_DISP_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_class_estup.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_ESTUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_ESTUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CLASS_ESTUP ', 'ALL',a.table_name, 'INF_CLASS_ESTUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CLASS_ESTUP ','ALL',a.table_name, 'INF_CLASS_ESTUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_class_estup_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_ESTUP_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_ESTUP_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CLASS_ESTUP_BCK ', 'ALL',a.table_name, 'INF_CLASS_ESTUP_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CLASS_ESTUP_BCK ','ALL',a.table_name, 'INF_CLASS_ESTUP_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_class_estup_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_ESTUP_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_CLASS_ESTUP_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_CLASS_ESTUP_NEW ', 'ALL',a.table_name, 'INF_CLASS_ESTUP_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_CLASS_ESTUP_NEW ','ALL',a.table_name, 'INF_CLASS_ESTUP_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_comerc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_COMERC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_COMERC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_COMERC ', 'ALL',a.table_name, 'INF_COMERC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_COMERC ','ALL',a.table_name, 'INF_COMERC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\inf_comerc_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_COMERC_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_COMERC_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_COMERC_BCK ', 'ALL',a.table_name, 'INF_COMERC_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_COMERC_BCK ','ALL',a.table_name, 'INF_COMERC_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_comerc_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_COMERC_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_COMERC_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_COMERC_NEW ', 'ALL',a.table_name, 'INF_COMERC_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_COMERC_NEW ','ALL',a.table_name, 'INF_COMERC_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_dcipt.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DCIPT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DCIPT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DCIPT ', 'ALL',a.table_name, 'INF_DCIPT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DCIPT ','ALL',a.table_name, 'INF_DCIPT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_dcipt_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DCIPT_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DCIPT_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DCIPT_BCK ', 'ALL',a.table_name, 'INF_DCIPT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DCIPT_BCK ','ALL',a.table_name, 'INF_DCIPT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_dcipt_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DCIPT_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DCIPT_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DCIPT_NEW ', 'ALL',a.table_name, 'INF_DCIPT_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DCIPT_NEW ','ALL',a.table_name, 'INF_DCIPT_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_diabetes_lnk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIABETES_LNK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIABETES_LNK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DIABETES_LNK ', 'ALL',a.table_name, 'INF_DIABETES_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DIABETES_LNK ','ALL',a.table_name, 'INF_DIABETES_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_diabetes_lnk_bck.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIABETES_LNK_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIABETES_LNK_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DIABETES_LNK_BCK ', 'ALL',a.table_name, 'INF_DIABETES_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DIABETES_LNK_BCK ','ALL',a.table_name, 'INF_DIABETES_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_diabetes_lnk_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIABETES_LNK_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIABETES_LNK_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DIABETES_LNK_NEW ', 'ALL',a.table_name, 'INF_DIABETES_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DIABETES_LNK_NEW ','ALL',a.table_name, 'INF_DIABETES_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_diploma.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIPLOMA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIPLOMA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DIPLOMA ', 'ALL',a.table_name, 'INF_DIPLOMA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DIPLOMA ','ALL',a.table_name, 'INF_DIPLOMA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_diploma_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIPLOMA_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIPLOMA_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DIPLOMA_BCK ', 'ALL',a.table_name, 'INF_DIPLOMA_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DIPLOMA_BCK ','ALL',a.table_name, 'INF_DIPLOMA_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_diploma_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIPLOMA_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DIPLOMA_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DIPLOMA_NEW ', 'ALL',a.table_name, 'INF_DIPLOMA_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DIPLOMA_NEW ','ALL',a.table_name, 'INF_DIPLOMA_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_dispo.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DISPO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DISPO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DISPO ', 'ALL',a.table_name, 'INF_DISPO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DISPO ','ALL',a.table_name, 'INF_DISPO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_dispo_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DISPO_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DISPO_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DISPO_BCK ', 'ALL',a.table_name, 'INF_DISPO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DISPO_BCK ','ALL',a.table_name, 'INF_DISPO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\inf_dispo_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DISPO_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_DISPO_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_DISPO_NEW ', 'ALL',a.table_name, 'INF_DISPO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_DISPO_NEW ','ALL',a.table_name, 'INF_DISPO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_emb.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB ', 'ALL',a.table_name, 'INF_EMB') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB ','ALL',a.table_name, 'INF_EMB') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_emb_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB_BCK ', 'ALL',a.table_name, 'INF_EMB_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB_BCK ','ALL',a.table_name, 'INF_EMB_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_emb_comerc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_COMERC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_COMERC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB_COMERC ', 'ALL',a.table_name, 'INF_EMB_COMERC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB_COMERC ','ALL',a.table_name, 'INF_EMB_COMERC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_emb_comerc_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_COMERC_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_COMERC_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB_COMERC_BCK ', 'ALL',a.table_name, 'INF_EMB_COMERC_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB_COMERC_BCK ','ALL',a.table_name, 'INF_EMB_COMERC_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_emb_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB_NEW ', 'ALL',a.table_name, 'INF_EMB_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB_NEW ','ALL',a.table_name, 'INF_EMB_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_emb_unit.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_UNIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_UNIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB_UNIT ', 'ALL',a.table_name, 'INF_EMB_UNIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB_UNIT ','ALL',a.table_name, 'INF_EMB_UNIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_emb_unit_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_UNIT_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_UNIT_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB_UNIT_BCK ', 'ALL',a.table_name, 'INF_EMB_UNIT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB_UNIT_BCK ','ALL',a.table_name, 'INF_EMB_UNIT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_emb_unit_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_UNIT_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_EMB_UNIT_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_EMB_UNIT_NEW ', 'ALL',a.table_name, 'INF_EMB_UNIT_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_EMB_UNIT_NEW ','ALL',a.table_name, 'INF_EMB_UNIT_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_estado_aim.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ESTADO_AIM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ESTADO_AIM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ESTADO_AIM ', 'ALL',a.table_name, 'INF_ESTADO_AIM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ESTADO_AIM ','ALL',a.table_name, 'INF_ESTADO_AIM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_estado_aim_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ESTADO_AIM_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ESTADO_AIM_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ESTADO_AIM_BCK ', 'ALL',a.table_name, 'INF_ESTADO_AIM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ESTADO_AIM_BCK ','ALL',a.table_name, 'INF_ESTADO_AIM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_estado_aim_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ESTADO_AIM_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_ESTADO_AIM_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_ESTADO_AIM_NEW ', 'ALL',a.table_name, 'INF_ESTADO_AIM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_ESTADO_AIM_NEW ','ALL',a.table_name, 'INF_ESTADO_AIM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_form_farm.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_FORM_FARM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_FORM_FARM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_FORM_FARM ', 'ALL',a.table_name, 'INF_FORM_FARM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_FORM_FARM ','ALL',a.table_name, 'INF_FORM_FARM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\inf_form_farm_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_FORM_FARM_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_FORM_FARM_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_FORM_FARM_BCK ', 'ALL',a.table_name, 'INF_FORM_FARM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_FORM_FARM_BCK ','ALL',a.table_name, 'INF_FORM_FARM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_form_farm_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_FORM_FARM_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_FORM_FARM_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_FORM_FARM_NEW ', 'ALL',a.table_name, 'INF_FORM_FARM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_FORM_FARM_NEW ','ALL',a.table_name, 'INF_FORM_FARM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_grupo_hom.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_GRUPO_HOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_GRUPO_HOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_GRUPO_HOM ', 'ALL',a.table_name, 'INF_GRUPO_HOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_GRUPO_HOM ','ALL',a.table_name, 'INF_GRUPO_HOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_grupo_hom_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_GRUPO_HOM_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_GRUPO_HOM_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_GRUPO_HOM_BCK ', 'ALL',a.table_name, 'INF_GRUPO_HOM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_GRUPO_HOM_BCK ','ALL',a.table_name, 'INF_GRUPO_HOM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_grupo_hom_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_GRUPO_HOM_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_GRUPO_HOM_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_GRUPO_HOM_NEW ', 'ALL',a.table_name, 'INF_GRUPO_HOM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_GRUPO_HOM_NEW ','ALL',a.table_name, 'INF_GRUPO_HOM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_med.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_MED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_MED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_MED ', 'ALL',a.table_name, 'INF_MED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_MED ','ALL',a.table_name, 'INF_MED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_med_bck.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_MED_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_MED_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_MED_BCK ', 'ALL',a.table_name, 'INF_MED_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_MED_BCK ','ALL',a.table_name, 'INF_MED_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_med_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_MED_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_MED_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_MED_NEW ', 'ALL',a.table_name, 'INF_MED_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_MED_NEW ','ALL',a.table_name, 'INF_MED_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_patol_dip_lnk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_DIP_LNK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_DIP_LNK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_DIP_LNK ', 'ALL',a.table_name, 'INF_PATOL_DIP_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_DIP_LNK ','ALL',a.table_name, 'INF_PATOL_DIP_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_patol_dip_lnk_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_DIP_LNK_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_DIP_LNK_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_DIP_LNK_BCK ', 'ALL',a.table_name, 'INF_PATOL_DIP_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_DIP_LNK_BCK ','ALL',a.table_name, 'INF_PATOL_DIP_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_patol_dip_lnk_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_DIP_LNK_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_DIP_LNK_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_DIP_LNK_NEW ', 'ALL',a.table_name, 'INF_PATOL_DIP_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_DIP_LNK_NEW ','ALL',a.table_name, 'INF_PATOL_DIP_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_patol_esp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_ESP ', 'ALL',a.table_name, 'INF_PATOL_ESP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_ESP ','ALL',a.table_name, 'INF_PATOL_ESP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_patol_esp_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_ESP_BCK ', 'ALL',a.table_name, 'INF_PATOL_ESP_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_ESP_BCK ','ALL',a.table_name, 'INF_PATOL_ESP_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\inf_patol_esp_lnk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_LNK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_LNK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_ESP_LNK ', 'ALL',a.table_name, 'INF_PATOL_ESP_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_ESP_LNK ','ALL',a.table_name, 'INF_PATOL_ESP_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_patol_esp_lnk_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_LNK_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_LNK_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_ESP_LNK_BCK ', 'ALL',a.table_name, 'INF_PATOL_ESP_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_ESP_LNK_BCK ','ALL',a.table_name, 'INF_PATOL_ESP_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_patol_esp_lnk_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_LNK_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_LNK_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_ESP_LNK_NEW ', 'ALL',a.table_name, 'INF_PATOL_ESP_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_ESP_LNK_NEW ','ALL',a.table_name, 'INF_PATOL_ESP_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_patol_esp_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PATOL_ESP_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PATOL_ESP_NEW ', 'ALL',a.table_name, 'INF_PATOL_ESP_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PATOL_ESP_NEW ','ALL',a.table_name, 'INF_PATOL_ESP_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_preco.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PRECO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PRECO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PRECO ', 'ALL',a.table_name, 'INF_PRECO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PRECO ','ALL',a.table_name, 'INF_PRECO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_preco_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PRECO_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PRECO_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PRECO_BCK ', 'ALL',a.table_name, 'INF_PRECO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PRECO_BCK ','ALL',a.table_name, 'INF_PRECO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_preco_new.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PRECO_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_PRECO_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_PRECO_NEW ', 'ALL',a.table_name, 'INF_PRECO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_PRECO_NEW ','ALL',a.table_name, 'INF_PRECO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_subst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_SUBST ', 'ALL',a.table_name, 'INF_SUBST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_SUBST ','ALL',a.table_name, 'INF_SUBST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_subst_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_SUBST_BCK ', 'ALL',a.table_name, 'INF_SUBST_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_SUBST_BCK ','ALL',a.table_name, 'INF_SUBST_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_subst_lnk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_LNK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_LNK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_SUBST_LNK ', 'ALL',a.table_name, 'INF_SUBST_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_SUBST_LNK ','ALL',a.table_name, 'INF_SUBST_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_subst_lnk_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_LNK_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_LNK_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_SUBST_LNK_BCK ', 'ALL',a.table_name, 'INF_SUBST_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_SUBST_LNK_BCK ','ALL',a.table_name, 'INF_SUBST_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_subst_lnk_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_LNK_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_LNK_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_SUBST_LNK_NEW ', 'ALL',a.table_name, 'INF_SUBST_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_SUBST_LNK_NEW ','ALL',a.table_name, 'INF_SUBST_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_subst_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_SUBST_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_SUBST_NEW ', 'ALL',a.table_name, 'INF_SUBST_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_SUBST_NEW ','ALL',a.table_name, 'INF_SUBST_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\inf_tipo_diab_mel.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_DIAB_MEL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_DIAB_MEL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_DIAB_MEL ', 'ALL',a.table_name, 'INF_TIPO_DIAB_MEL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_DIAB_MEL ','ALL',a.table_name, 'INF_TIPO_DIAB_MEL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tipo_diab_mel_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_DIAB_MEL_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_DIAB_MEL_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_DIAB_MEL_BCK ', 'ALL',a.table_name, 'INF_TIPO_DIAB_MEL_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_DIAB_MEL_BCK ','ALL',a.table_name, 'INF_TIPO_DIAB_MEL_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_tipo_diab_mel_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_DIAB_MEL_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_DIAB_MEL_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_DIAB_MEL_NEW ', 'ALL',a.table_name, 'INF_TIPO_DIAB_MEL_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_DIAB_MEL_NEW ','ALL',a.table_name, 'INF_TIPO_DIAB_MEL_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tipo_preco.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PRECO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PRECO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_PRECO ', 'ALL',a.table_name, 'INF_TIPO_PRECO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_PRECO ','ALL',a.table_name, 'INF_TIPO_PRECO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_tipo_preco_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PRECO_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PRECO_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_PRECO_BCK ', 'ALL',a.table_name, 'INF_TIPO_PRECO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_PRECO_BCK ','ALL',a.table_name, 'INF_TIPO_PRECO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tipo_preco_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PRECO_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PRECO_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_PRECO_NEW ', 'ALL',a.table_name, 'INF_TIPO_PRECO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_PRECO_NEW ','ALL',a.table_name, 'INF_TIPO_PRECO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tipo_prod.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PROD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PROD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_PROD ', 'ALL',a.table_name, 'INF_TIPO_PROD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_PROD ','ALL',a.table_name, 'INF_TIPO_PROD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tipo_prod_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PROD_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PROD_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_PROD_BCK ', 'ALL',a.table_name, 'INF_TIPO_PROD_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_PROD_BCK ','ALL',a.table_name, 'INF_TIPO_PROD_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tipo_prod_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PROD_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TIPO_PROD_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TIPO_PROD_NEW ', 'ALL',a.table_name, 'INF_TIPO_PROD_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TIPO_PROD_NEW ','ALL',a.table_name, 'INF_TIPO_PROD_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_titular_aim.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TITULAR_AIM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TITULAR_AIM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TITULAR_AIM ', 'ALL',a.table_name, 'INF_TITULAR_AIM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TITULAR_AIM ','ALL',a.table_name, 'INF_TITULAR_AIM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_titular_aim_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TITULAR_AIM_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TITULAR_AIM_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TITULAR_AIM_BCK ', 'ALL',a.table_name, 'INF_TITULAR_AIM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TITULAR_AIM_BCK ','ALL',a.table_name, 'INF_TITULAR_AIM_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_titular_aim_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TITULAR_AIM_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TITULAR_AIM_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TITULAR_AIM_NEW ', 'ALL',a.table_name, 'INF_TITULAR_AIM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TITULAR_AIM_NEW ','ALL',a.table_name, 'INF_TITULAR_AIM_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tratamento.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TRATAMENTO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TRATAMENTO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TRATAMENTO ', 'ALL',a.table_name, 'INF_TRATAMENTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TRATAMENTO ','ALL',a.table_name, 'INF_TRATAMENTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\inf_tratamento_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TRATAMENTO_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TRATAMENTO_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TRATAMENTO_BCK ', 'ALL',a.table_name, 'INF_TRATAMENTO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TRATAMENTO_BCK ','ALL',a.table_name, 'INF_TRATAMENTO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_tratamento_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TRATAMENTO_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_TRATAMENTO_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_TRATAMENTO_NEW ', 'ALL',a.table_name, 'INF_TRATAMENTO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_TRATAMENTO_NEW ','ALL',a.table_name, 'INF_TRATAMENTO_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_vias_admin.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_VIAS_ADMIN ', 'ALL',a.table_name, 'INF_VIAS_ADMIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_VIAS_ADMIN ','ALL',a.table_name, 'INF_VIAS_ADMIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_vias_admin_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_VIAS_ADMIN_BCK ', 'ALL',a.table_name, 'INF_VIAS_ADMIN_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_VIAS_ADMIN_BCK ','ALL',a.table_name, 'INF_VIAS_ADMIN_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\inf_vias_admin_lnk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_LNK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_LNK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_VIAS_ADMIN_LNK ', 'ALL',a.table_name, 'INF_VIAS_ADMIN_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_VIAS_ADMIN_LNK ','ALL',a.table_name, 'INF_VIAS_ADMIN_LNK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_vias_admin_lnk_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_LNK_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_LNK_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_VIAS_ADMIN_LNK_BCK ', 'ALL',a.table_name, 'INF_VIAS_ADMIN_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_VIAS_ADMIN_LNK_BCK ','ALL',a.table_name, 'INF_VIAS_ADMIN_LNK_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_vias_admin_lnk_new.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_LNK_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_LNK_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_VIAS_ADMIN_LNK_NEW ', 'ALL',a.table_name, 'INF_VIAS_ADMIN_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_VIAS_ADMIN_LNK_NEW ','ALL',a.table_name, 'INF_VIAS_ADMIN_LNK_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inf_vias_admin_new.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_NEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INF_VIAS_ADMIN_NEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INF_VIAS_ADMIN_NEW ', 'ALL',a.table_name, 'INF_VIAS_ADMIN_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INF_VIAS_ADMIN_NEW ','ALL',a.table_name, 'INF_VIAS_ADMIN_NEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\ingredient.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INGREDIENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INGREDIENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INGREDIENT ', 'ALL',a.table_name, 'INGREDIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INGREDIENT ','ALL',a.table_name, 'INGREDIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inp_error.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INP_ERROR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INP_ERROR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INP_ERROR ', 'ALL',a.table_name, 'INP_ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INP_ERROR ','ALL',a.table_name, 'INP_ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\inp_log.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INP_LOG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INP_LOG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INP_LOG ', 'ALL',a.table_name, 'INP_LOG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INP_LOG ','ALL',a.table_name, 'INP_LOG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\instit_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INSTIT_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INSTIT_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INSTIT_EXT_SYS ', 'ALL',a.table_name, 'INSTIT_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INSTIT_EXT_SYS ','ALL',a.table_name, 'INSTIT_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\institution.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INSTITUTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INSTITUTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INSTITUTION ', 'ALL',a.table_name, 'INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INSTITUTION ','ALL',a.table_name, 'INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\interv_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_DEP_CLIN_SERV ', 'ALL',a.table_name, 'INTERV_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_DEP_CLIN_SERV ','ALL',a.table_name, 'INTERV_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_dep_clin_serv_migra.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DEP_CLIN_SERV_MIGRA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DEP_CLIN_SERV_MIGRA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_DEP_CLIN_SERV_MIGRA ', 'ALL',a.table_name, 'INTERV_DEP_CLIN_SERV_MIGRA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_DEP_CLIN_SERV_MIGRA ','ALL',a.table_name, 'INTERV_DEP_CLIN_SERV_MIGRA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\interv_dep_clin_serv_20060303.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DEP_CLIN_SERV_20060303','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DEP_CLIN_SERV_20060303','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_DEP_CLIN_SERV_20060303 ', 'ALL',a.table_name, 'INTERV_DEP_CLIN_SERV_20060303') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_DEP_CLIN_SERV_20060303 ','ALL',a.table_name, 'INTERV_DEP_CLIN_SERV_20060303') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_drug.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DRUG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_DRUG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_DRUG ', 'ALL',a.table_name, 'INTERV_DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_DRUG ','ALL',a.table_name, 'INTERV_DRUG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\intervention.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERVENTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERVENTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERVENTION ', 'ALL',a.table_name, 'INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERVENTION ','ALL',a.table_name, 'INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_ext_sys_delete.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_EXT_SYS_DELETE ', 'ALL',a.table_name, 'INTERV_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_EXT_SYS_DELETE ','ALL',a.table_name, 'INTERV_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_physiatry_area.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PHYSIATRY_AREA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PHYSIATRY_AREA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_PHYSIATRY_AREA ', 'ALL',a.table_name, 'INTERV_PHYSIATRY_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_PHYSIATRY_AREA ','ALL',a.table_name, 'INTERV_PHYSIATRY_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_prep_msg.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PREP_MSG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PREP_MSG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_PREP_MSG ', 'ALL',a.table_name, 'INTERV_PREP_MSG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_PREP_MSG ','ALL',a.table_name, 'INTERV_PREP_MSG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_presc_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PRESC_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PRESC_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_PRESC_DET ', 'ALL',a.table_name, 'INTERV_PRESC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_PRESC_DET ','ALL',a.table_name, 'INTERV_PRESC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_presc_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PRESC_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PRESC_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_PRESC_PLAN ', 'ALL',a.table_name, 'INTERV_PRESC_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_PRESC_PLAN ','ALL',a.table_name, 'INTERV_PRESC_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_prescription.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PRESCRIPTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PRESCRIPTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_PRESCRIPTION ', 'ALL',a.table_name, 'INTERV_PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_PRESCRIPTION ','ALL',a.table_name, 'INTERV_PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_PROTOCOLS ', 'ALL',a.table_name, 'INTERV_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_PROTOCOLS ','ALL',a.table_name, 'INTERV_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\interv_room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','INTERV_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('INTERV_ROOM ', 'ALL',a.table_name, 'INTERV_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('INTERV_ROOM ','ALL',a.table_name, 'INTERV_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\isencao.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ISENCAO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ISENCAO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ISENCAO ', 'ALL',a.table_name, 'ISENCAO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ISENCAO ','ALL',a.table_name, 'ISENCAO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\java$class$md5$table.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','JAVA$CLASS$MD5$TABLE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','JAVA$CLASS$MD5$TABLE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('JAVA$CLASS$MD5$TABLE ', 'ALL',a.table_name, 'JAVA$CLASS$MD5$TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('JAVA$CLASS$MD5$TABLE ','ALL',a.table_name, 'JAVA$CLASS$MD5$TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\java$options.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','JAVA$OPTIONS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','JAVA$OPTIONS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('JAVA$OPTIONS ', 'ALL',a.table_name, 'JAVA$OPTIONS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('JAVA$OPTIONS ','ALL',a.table_name, 'JAVA$OPTIONS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\language.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','LANGUAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','LANGUAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('LANGUAGE ', 'ALL',a.table_name, 'LANGUAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('LANGUAGE ','ALL',a.table_name, 'LANGUAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\lixo.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','LIXO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','LIXO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('LIXO ', 'ALL',a.table_name, 'LIXO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('LIXO ','ALL',a.table_name, 'LIXO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\manchester.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MANCHESTER','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MANCHESTER','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MANCHESTER ', 'ALL',a.table_name, 'MANCHESTER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MANCHESTER ','ALL',a.table_name, 'MANCHESTER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\manipulated.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MANIPULATED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MANIPULATED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MANIPULATED ', 'ALL',a.table_name, 'MANIPULATED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MANIPULATED ','ALL',a.table_name, 'MANIPULATED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\manipulated_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MANIPULATED_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MANIPULATED_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MANIPULATED_GROUP ', 'ALL',a.table_name, 'MANIPULATED_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MANIPULATED_GROUP ','ALL',a.table_name, 'MANIPULATED_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\manipulated_ingredient.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MANIPULATED_INGREDIENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MANIPULATED_INGREDIENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MANIPULATED_INGREDIENT ', 'ALL',a.table_name, 'MANIPULATED_INGREDIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MANIPULATED_INGREDIENT ','ALL',a.table_name, 'MANIPULATED_INGREDIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\match_epis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATCH_EPIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATCH_EPIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATCH_EPIS ', 'ALL',a.table_name, 'MATCH_EPIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATCH_EPIS ','ALL',a.table_name, 'MATCH_EPIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\material.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATERIAL ', 'ALL',a.table_name, 'MATERIAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATERIAL ','ALL',a.table_name, 'MATERIAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\material_protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATERIAL_PROTOCOLS ', 'ALL',a.table_name, 'MATERIAL_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATERIAL_PROTOCOLS ','ALL',a.table_name, 'MATERIAL_PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\material_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATERIAL_REQ ', 'ALL',a.table_name, 'MATERIAL_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATERIAL_REQ ','ALL',a.table_name, 'MATERIAL_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\material_req_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_REQ_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_REQ_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATERIAL_REQ_DET ', 'ALL',a.table_name, 'MATERIAL_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATERIAL_REQ_DET ','ALL',a.table_name, 'MATERIAL_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\material_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATERIAL_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATERIAL_TYPE ', 'ALL',a.table_name, 'MATERIAL_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATERIAL_TYPE ','ALL',a.table_name, 'MATERIAL_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\matr_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATR_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATR_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATR_DEP_CLIN_SERV ', 'ALL',a.table_name, 'MATR_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATR_DEP_CLIN_SERV ','ALL',a.table_name, 'MATR_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\matr_room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATR_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATR_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATR_ROOM ', 'ALL',a.table_name, 'MATR_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATR_ROOM ','ALL',a.table_name, 'MATR_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\matr_scheduled.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MATR_SCHEDULED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MATR_SCHEDULED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MATR_SCHEDULED ', 'ALL',a.table_name, 'MATR_SCHEDULED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MATR_SCHEDULED ','ALL',a.table_name, 'MATR_SCHEDULED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\mcdt_req_diagnosis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MCDT_REQ_DIAGNOSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MCDT_REQ_DIAGNOSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MCDT_REQ_DIAGNOSIS ', 'ALL',a.table_name, 'MCDT_REQ_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MCDT_REQ_DIAGNOSIS ','ALL',a.table_name, 'MCDT_REQ_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\mdm_coding.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MDM_CODING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MDM_CODING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MDM_CODING ', 'ALL',a.table_name, 'MDM_CODING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MDM_CODING ','ALL',a.table_name, 'MDM_CODING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\mdm_evaluation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MDM_EVALUATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MDM_EVALUATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MDM_EVALUATION ', 'ALL',a.table_name, 'MDM_EVALUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MDM_EVALUATION ','ALL',a.table_name, 'MDM_EVALUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\mdm_prof_coding.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MDM_PROF_CODING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MDM_PROF_CODING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MDM_PROF_CODING ', 'ALL',a.table_name, 'MDM_PROF_CODING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MDM_PROF_CODING ','ALL',a.table_name, 'MDM_PROF_CODING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\monitorization.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MONITORIZATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MONITORIZATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MONITORIZATION ', 'ALL',a.table_name, 'MONITORIZATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MONITORIZATION ','ALL',a.table_name, 'MONITORIZATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\monitorization_vs.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MONITORIZATION_VS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MONITORIZATION_VS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MONITORIZATION_VS ', 'ALL',a.table_name, 'MONITORIZATION_VS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MONITORIZATION_VS ','ALL',a.table_name, 'MONITORIZATION_VS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\monitorization_vs_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MONITORIZATION_VS_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MONITORIZATION_VS_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MONITORIZATION_VS_PLAN ', 'ALL',a.table_name, 'MONITORIZATION_VS_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MONITORIZATION_VS_PLAN ','ALL',a.table_name, 'MONITORIZATION_VS_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\movement.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','MOVEMENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','MOVEMENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('MOVEMENT ', 'ALL',a.table_name, 'MOVEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('MOVEMENT ','ALL',a.table_name, 'MOVEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\necessity.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','NECESSITY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','NECESSITY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('NECESSITY ', 'ALL',a.table_name, 'NECESSITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('NECESSITY ','ALL',a.table_name, 'NECESSITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\nurse_activity_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_ACTIVITY_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_ACTIVITY_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('NURSE_ACTIVITY_REQ ', 'ALL',a.table_name, 'NURSE_ACTIVITY_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('NURSE_ACTIVITY_REQ ','ALL',a.table_name, 'NURSE_ACTIVITY_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\nurse_actv_req_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_ACTV_REQ_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_ACTV_REQ_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('NURSE_ACTV_REQ_DET ', 'ALL',a.table_name, 'NURSE_ACTV_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('NURSE_ACTV_REQ_DET ','ALL',a.table_name, 'NURSE_ACTV_REQ_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\nurse_discharge.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_DISCHARGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_DISCHARGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('NURSE_DISCHARGE ', 'ALL',a.table_name, 'NURSE_DISCHARGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('NURSE_DISCHARGE ','ALL',a.table_name, 'NURSE_DISCHARGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\nurse_tea_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_TEA_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','NURSE_TEA_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('NURSE_TEA_REQ ', 'ALL',a.table_name, 'NURSE_TEA_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('NURSE_TEA_REQ ','ALL',a.table_name, 'NURSE_TEA_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\occupation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','OCCUPATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','OCCUPATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('OCCUPATION ', 'ALL',a.table_name, 'OCCUPATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('OCCUPATION ','ALL',a.table_name, 'OCCUPATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\opinion.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','OPINION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','OPINION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('OPINION ', 'ALL',a.table_name, 'OPINION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('OPINION ','ALL',a.table_name, 'OPINION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\opinion_prof.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','OPINION_PROF','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','OPINION_PROF','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('OPINION_PROF ', 'ALL',a.table_name, 'OPINION_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('OPINION_PROF ','ALL',a.table_name, 'OPINION_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\origin.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ORIGIN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ORIGIN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ORIGIN ', 'ALL',a.table_name, 'ORIGIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ORIGIN ','ALL',a.table_name, 'ORIGIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\origin_soft.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ORIGIN_SOFT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ORIGIN_SOFT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ORIGIN_SOFT ', 'ALL',a.table_name, 'ORIGIN_SOFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ORIGIN_SOFT ','ALL',a.table_name, 'ORIGIN_SOFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\outlook.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','OUTLOOK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','OUTLOOK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('OUTLOOK ', 'ALL',a.table_name, 'OUTLOOK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('OUTLOOK ','ALL',a.table_name, 'OUTLOOK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\param_analysis_ext_sys_delete.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PARAM_ANALYSIS_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PARAM_ANALYSIS_EXT_SYS_DELETE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PARAM_ANALYSIS_EXT_SYS_DELETE ', 'ALL',a.table_name, 'PARAM_ANALYSIS_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PARAM_ANALYSIS_EXT_SYS_DELETE ','ALL',a.table_name, 'PARAM_ANALYSIS_EXT_SYS_DELETE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\parameter_analysis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PARAMETER_ANALYSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PARAMETER_ANALYSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PARAMETER_ANALYSIS ', 'ALL',a.table_name, 'PARAMETER_ANALYSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PARAMETER_ANALYSIS ','ALL',a.table_name, 'PARAMETER_ANALYSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\pat_allergy.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_ALLERGY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_ALLERGY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_ALLERGY ', 'ALL',a.table_name, 'PAT_ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_ALLERGY ','ALL',a.table_name, 'PAT_ALLERGY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_allergy_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_ALLERGY_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_ALLERGY_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_ALLERGY_HIST ', 'ALL',a.table_name, 'PAT_ALLERGY_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_ALLERGY_HIST ','ALL',a.table_name, 'PAT_ALLERGY_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_blood_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_BLOOD_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_BLOOD_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_BLOOD_GROUP ', 'ALL',a.table_name, 'PAT_BLOOD_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_BLOOD_GROUP ','ALL',a.table_name, 'PAT_BLOOD_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_child_clin_rec.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CHILD_CLIN_REC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CHILD_CLIN_REC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_CHILD_CLIN_REC ', 'ALL',a.table_name, 'PAT_CHILD_CLIN_REC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_CHILD_CLIN_REC ','ALL',a.table_name, 'PAT_CHILD_CLIN_REC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_child_feed_dev.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CHILD_FEED_DEV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CHILD_FEED_DEV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_CHILD_FEED_DEV ', 'ALL',a.table_name, 'PAT_CHILD_FEED_DEV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_CHILD_FEED_DEV ','ALL',a.table_name, 'PAT_CHILD_FEED_DEV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_cli_attributes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CLI_ATTRIBUTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CLI_ATTRIBUTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_CLI_ATTRIBUTES ', 'ALL',a.table_name, 'PAT_CLI_ATTRIBUTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_CLI_ATTRIBUTES ','ALL',a.table_name, 'PAT_CLI_ATTRIBUTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_cntrceptiv.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CNTRCEPTIV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_CNTRCEPTIV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_CNTRCEPTIV ', 'ALL',a.table_name, 'PAT_CNTRCEPTIV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_CNTRCEPTIV ','ALL',a.table_name, 'PAT_CNTRCEPTIV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_delivery.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_DELIVERY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_DELIVERY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_DELIVERY ', 'ALL',a.table_name, 'PAT_DELIVERY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_DELIVERY ','ALL',a.table_name, 'PAT_DELIVERY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_dmgr_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_DMGR_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_DMGR_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_DMGR_HIST ', 'ALL',a.table_name, 'PAT_DMGR_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_DMGR_HIST ','ALL',a.table_name, 'PAT_DMGR_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_doc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_DOC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_DOC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_DOC ', 'ALL',a.table_name, 'PAT_DOC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_DOC ','ALL',a.table_name, 'PAT_DOC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_EXT_SYS ', 'ALL',a.table_name, 'PAT_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_EXT_SYS ','ALL',a.table_name, 'PAT_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_family.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_FAMILY ', 'ALL',a.table_name, 'PAT_FAMILY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_FAMILY ','ALL',a.table_name, 'PAT_FAMILY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_family_disease.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY_DISEASE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY_DISEASE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_FAMILY_DISEASE ', 'ALL',a.table_name, 'PAT_FAMILY_DISEASE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_FAMILY_DISEASE ','ALL',a.table_name, 'PAT_FAMILY_DISEASE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\pat_family_member.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY_MEMBER','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY_MEMBER','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_FAMILY_MEMBER ', 'ALL',a.table_name, 'PAT_FAMILY_MEMBER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_FAMILY_MEMBER ','ALL',a.table_name, 'PAT_FAMILY_MEMBER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_family_prof.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY_PROF','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAMILY_PROF','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_FAMILY_PROF ', 'ALL',a.table_name, 'PAT_FAMILY_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_FAMILY_PROF ','ALL',a.table_name, 'PAT_FAMILY_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_fam_soc_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAM_SOC_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_FAM_SOC_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_FAM_SOC_HIST ', 'ALL',a.table_name, 'PAT_FAM_SOC_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_FAM_SOC_HIST ','ALL',a.table_name, 'PAT_FAM_SOC_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_ginec.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_GINEC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_GINEC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_GINEC ', 'ALL',a.table_name, 'PAT_GINEC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_GINEC ','ALL',a.table_name, 'PAT_GINEC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_ginec_obstet.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_GINEC_OBSTET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_GINEC_OBSTET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_GINEC_OBSTET ', 'ALL',a.table_name, 'PAT_GINEC_OBSTET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_GINEC_OBSTET ','ALL',a.table_name, 'PAT_GINEC_OBSTET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_graffar_crit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_GRAFFAR_CRIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_GRAFFAR_CRIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_GRAFFAR_CRIT ', 'ALL',a.table_name, 'PAT_GRAFFAR_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_GRAFFAR_CRIT ','ALL',a.table_name, 'PAT_GRAFFAR_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_habit.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HABIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HABIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_HABIT ', 'ALL',a.table_name, 'PAT_HABIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_HABIT ','ALL',a.table_name, 'PAT_HABIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_health_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HEALTH_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HEALTH_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_HEALTH_PLAN ', 'ALL',a.table_name, 'PAT_HEALTH_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_HEALTH_PLAN ','ALL',a.table_name, 'PAT_HEALTH_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_history.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HISTORY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HISTORY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_HISTORY ', 'ALL',a.table_name, 'PAT_HISTORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_HISTORY ','ALL',a.table_name, 'PAT_HISTORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_history_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HISTORY_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HISTORY_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_HISTORY_HIST ', 'ALL',a.table_name, 'PAT_HISTORY_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_HISTORY_HIST ','ALL',a.table_name, 'PAT_HISTORY_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_history_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HISTORY_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_HISTORY_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_HISTORY_TYPE ', 'ALL',a.table_name, 'PAT_HISTORY_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_HISTORY_TYPE ','ALL',a.table_name, 'PAT_HISTORY_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\patient.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PATIENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PATIENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PATIENT ', 'ALL',a.table_name, 'PATIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PATIENT ','ALL',a.table_name, 'PATIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_job.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_JOB','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_JOB','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_JOB ', 'ALL',a.table_name, 'PAT_JOB') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_JOB ','ALL',a.table_name, 'PAT_JOB') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\pat_med_decl.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MED_DECL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MED_DECL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_MED_DECL ', 'ALL',a.table_name, 'PAT_MED_DECL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_MED_DECL ','ALL',a.table_name, 'PAT_MED_DECL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_medication.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MEDICATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MEDICATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_MEDICATION ', 'ALL',a.table_name, 'PAT_MEDICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_MEDICATION ','ALL',a.table_name, 'PAT_MEDICATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_medication_hist_list.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MEDICATION_HIST_LIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MEDICATION_HIST_LIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_MEDICATION_HIST_LIST ', 'ALL',a.table_name, 'PAT_MEDICATION_HIST_LIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_MEDICATION_HIST_LIST ','ALL',a.table_name, 'PAT_MEDICATION_HIST_LIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_medication_list.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MEDICATION_LIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_MEDICATION_LIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_MEDICATION_LIST ', 'ALL',a.table_name, 'PAT_MEDICATION_LIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_MEDICATION_LIST ','ALL',a.table_name, 'PAT_MEDICATION_LIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_necessity.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_NECESSITY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_NECESSITY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_NECESSITY ', 'ALL',a.table_name, 'PAT_NECESSITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_NECESSITY ','ALL',a.table_name, 'PAT_NECESSITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_NOTES ', 'ALL',a.table_name, 'PAT_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_NOTES ','ALL',a.table_name, 'PAT_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_permission.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PERMISSION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PERMISSION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PERMISSION ', 'ALL',a.table_name, 'PAT_PERMISSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PERMISSION ','ALL',a.table_name, 'PAT_PERMISSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_photo.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PHOTO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PHOTO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PHOTO ', 'ALL',a.table_name, 'PAT_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PHOTO ','ALL',a.table_name, 'PAT_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_pregnancy.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGNANCY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGNANCY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PREGNANCY ', 'ALL',a.table_name, 'PAT_PREGNANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PREGNANCY ','ALL',a.table_name, 'PAT_PREGNANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_pregnancy_risk.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGNANCY_RISK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGNANCY_RISK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PREGNANCY_RISK ', 'ALL',a.table_name, 'PAT_PREGNANCY_RISK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PREGNANCY_RISK ','ALL',a.table_name, 'PAT_PREGNANCY_RISK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_pregn_fetus.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_FETUS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_FETUS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PREGN_FETUS ', 'ALL',a.table_name, 'PAT_PREGN_FETUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PREGN_FETUS ','ALL',a.table_name, 'PAT_PREGN_FETUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_pregn_fetus_biom.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_FETUS_BIOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_FETUS_BIOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PREGN_FETUS_BIOM ', 'ALL',a.table_name, 'PAT_PREGN_FETUS_BIOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PREGN_FETUS_BIOM ','ALL',a.table_name, 'PAT_PREGN_FETUS_BIOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_pregn_fetus_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_FETUS_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_FETUS_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PREGN_FETUS_DET ', 'ALL',a.table_name, 'PAT_PREGN_FETUS_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PREGN_FETUS_DET ','ALL',a.table_name, 'PAT_PREGN_FETUS_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\pat_pregn_measure.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_MEASURE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PREGN_MEASURE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PREGN_MEASURE ', 'ALL',a.table_name, 'PAT_PREGN_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PREGN_MEASURE ','ALL',a.table_name, 'PAT_PREGN_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_problem.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PROBLEM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PROBLEM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PROBLEM ', 'ALL',a.table_name, 'PAT_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PROBLEM ','ALL',a.table_name, 'PAT_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_problem_hist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PROBLEM_HIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PROBLEM_HIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PROBLEM_HIST ', 'ALL',a.table_name, 'PAT_PROBLEM_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PROBLEM_HIST ','ALL',a.table_name, 'PAT_PROBLEM_HIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_prob_visit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PROB_VISIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_PROB_VISIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_PROB_VISIT ', 'ALL',a.table_name, 'PAT_PROB_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_PROB_VISIT ','ALL',a.table_name, 'PAT_PROB_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\pat_sick_leave.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_SICK_LEAVE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_SICK_LEAVE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_SICK_LEAVE ', 'ALL',a.table_name, 'PAT_SICK_LEAVE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_SICK_LEAVE ','ALL',a.table_name, 'PAT_SICK_LEAVE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_soc_attributes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_SOC_ATTRIBUTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_SOC_ATTRIBUTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_SOC_ATTRIBUTES ', 'ALL',a.table_name, 'PAT_SOC_ATTRIBUTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_SOC_ATTRIBUTES ','ALL',a.table_name, 'PAT_SOC_ATTRIBUTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_tmp_remota.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_TMP_REMOTA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_TMP_REMOTA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_TMP_REMOTA ', 'ALL',a.table_name, 'PAT_TMP_REMOTA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_TMP_REMOTA ','ALL',a.table_name, 'PAT_TMP_REMOTA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\pat_vaccine.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_VACCINE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PAT_VACCINE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PAT_VACCINE ', 'ALL',a.table_name, 'PAT_VACCINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PAT_VACCINE ','ALL',a.table_name, 'PAT_VACCINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\periodic_exam_educ.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PERIODIC_EXAM_EDUC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PERIODIC_EXAM_EDUC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PERIODIC_EXAM_EDUC ', 'ALL',a.table_name, 'PERIODIC_EXAM_EDUC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PERIODIC_EXAM_EDUC ','ALL',a.table_name, 'PERIODIC_EXAM_EDUC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\plan_table.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PLAN_TABLE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PLAN_TABLE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PLAN_TABLE ', 'ALL',a.table_name, 'PLAN_TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PLAN_TABLE ','ALL',a.table_name, 'PLAN_TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\positioning.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','POSITIONING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','POSITIONING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('POSITIONING ', 'ALL',a.table_name, 'POSITIONING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('POSITIONING ','ALL',a.table_name, 'POSITIONING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\positioning_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','POSITIONING_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','POSITIONING_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('POSITIONING_TYPE ', 'ALL',a.table_name, 'POSITIONING_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('POSITIONING_TYPE ','ALL',a.table_name, 'POSITIONING_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\postal_code_pt.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','POSTAL_CODE_PT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','POSTAL_CODE_PT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('POSTAL_CODE_PT ', 'ALL',a.table_name, 'POSTAL_CODE_PT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('POSTAL_CODE_PT ','ALL',a.table_name, 'POSTAL_CODE_PT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\pregnancy_risk_eval.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PREGNANCY_RISK_EVAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PREGNANCY_RISK_EVAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PREGNANCY_RISK_EVAL ', 'ALL',a.table_name, 'PREGNANCY_RISK_EVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PREGNANCY_RISK_EVAL ','ALL',a.table_name, 'PREGNANCY_RISK_EVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prep_message.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PREP_MESSAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PREP_MESSAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PREP_MESSAGE ', 'ALL',a.table_name, 'PREP_MESSAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PREP_MESSAGE ','ALL',a.table_name, 'PREP_MESSAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\presc_attention_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESC_ATTENTION_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESC_ATTENTION_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESC_ATTENTION_DET ', 'ALL',a.table_name, 'PRESC_ATTENTION_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESC_ATTENTION_DET ','ALL',a.table_name, 'PRESC_ATTENTION_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\presc_pat_problem.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESC_PAT_PROBLEM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESC_PAT_PROBLEM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESC_PAT_PROBLEM ', 'ALL',a.table_name, 'PRESC_PAT_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESC_PAT_PROBLEM ','ALL',a.table_name, 'PRESC_PAT_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\prescription.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION ', 'ALL',a.table_name, 'PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION ','ALL',a.table_name, 'PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_number_seq.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_NUMBER_SEQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_NUMBER_SEQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_NUMBER_SEQ ', 'ALL',a.table_name, 'PRESCRIPTION_NUMBER_SEQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_NUMBER_SEQ ','ALL',a.table_name, 'PRESCRIPTION_NUMBER_SEQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_pharm.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_PHARM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_PHARM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_PHARM ', 'ALL',a.table_name, 'PRESCRIPTION_PHARM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_PHARM ','ALL',a.table_name, 'PRESCRIPTION_PHARM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_pharm_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_PHARM_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_PHARM_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_PHARM_DET ', 'ALL',a.table_name, 'PRESCRIPTION_PHARM_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_PHARM_DET ','ALL',a.table_name, 'PRESCRIPTION_PHARM_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_print.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_PRINT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_PRINT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_PRINT ', 'ALL',a.table_name, 'PRESCRIPTION_PRINT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_PRINT ','ALL',a.table_name, 'PRESCRIPTION_PRINT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_TYPE ', 'ALL',a.table_name, 'PRESCRIPTION_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_TYPE ','ALL',a.table_name, 'PRESCRIPTION_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_type_access.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_TYPE_ACCESS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_TYPE_ACCESS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_TYPE_ACCESS ', 'ALL',a.table_name, 'PRESCRIPTION_TYPE_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_TYPE_ACCESS ','ALL',a.table_name, 'PRESCRIPTION_TYPE_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_xml.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_XML','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_XML','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_XML ', 'ALL',a.table_name, 'PRESCRIPTION_XML') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_XML ','ALL',a.table_name, 'PRESCRIPTION_XML') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prescription_xml_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_XML_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PRESCRIPTION_XML_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PRESCRIPTION_XML_DET ', 'ALL',a.table_name, 'PRESCRIPTION_XML_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PRESCRIPTION_XML_DET ','ALL',a.table_name, 'PRESCRIPTION_XML_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\prev_episodes_temp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PREV_EPISODES_TEMP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PREV_EPISODES_TEMP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PREV_EPISODES_TEMP ', 'ALL',a.table_name, 'PREV_EPISODES_TEMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PREV_EPISODES_TEMP ','ALL',a.table_name, 'PREV_EPISODES_TEMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_access.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_ACCESS ', 'ALL',a.table_name, 'PROF_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_ACCESS ','ALL',a.table_name, 'PROF_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\prof_access_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_ACCESS_BCK ', 'ALL',a.table_name, 'PROF_ACCESS_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_ACCESS_BCK ','ALL',a.table_name, 'PROF_ACCESS_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_access_bck1.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK1','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK1','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_ACCESS_BCK1 ', 'ALL',a.table_name, 'PROF_ACCESS_BCK1') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_ACCESS_BCK1 ','ALL',a.table_name, 'PROF_ACCESS_BCK1') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\prof_access_bck2.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK2','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK2','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_ACCESS_BCK2 ', 'ALL',a.table_name, 'PROF_ACCESS_BCK2') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_ACCESS_BCK2 ','ALL',a.table_name, 'PROF_ACCESS_BCK2') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_access_bck_20070214.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK_20070214','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_BCK_20070214','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_ACCESS_BCK_20070214 ', 'ALL',a.table_name, 'PROF_ACCESS_BCK_20070214') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_ACCESS_BCK_20070214 ','ALL',a.table_name, 'PROF_ACCESS_BCK_20070214') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_access_field_func.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_FIELD_FUNC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ACCESS_FIELD_FUNC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_ACCESS_FIELD_FUNC ', 'ALL',a.table_name, 'PROF_ACCESS_FIELD_FUNC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_ACCESS_FIELD_FUNC ','ALL',a.table_name, 'PROF_ACCESS_FIELD_FUNC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_cat.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_CAT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_CAT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_CAT ', 'ALL',a.table_name, 'PROF_CAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_CAT ','ALL',a.table_name, 'PROF_CAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_DEP_CLIN_SERV ', 'ALL',a.table_name, 'PROF_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_DEP_CLIN_SERV ','ALL',a.table_name, 'PROF_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_doc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_DOC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_DOC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_DOC ', 'ALL',a.table_name, 'PROF_DOC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_DOC ','ALL',a.table_name, 'PROF_DOC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_epis_interv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_EPIS_INTERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_EPIS_INTERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_EPIS_INTERV ', 'ALL',a.table_name, 'PROF_EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_EPIS_INTERV ','ALL',a.table_name, 'PROF_EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\professional.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROFESSIONAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROFESSIONAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROFESSIONAL ', 'ALL',a.table_name, 'PROFESSIONAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROFESSIONAL ','ALL',a.table_name, 'PROFESSIONAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_EXT_SYS ', 'ALL',a.table_name, 'PROF_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_EXT_SYS ','ALL',a.table_name, 'PROF_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\prof_func.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_FUNC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_FUNC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_FUNC ', 'ALL',a.table_name, 'PROF_FUNC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_FUNC ','ALL',a.table_name, 'PROF_FUNC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\profile_templ_access.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPL_ACCESS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPL_ACCESS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROFILE_TEMPL_ACCESS ', 'ALL',a.table_name, 'PROFILE_TEMPL_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROFILE_TEMPL_ACCESS ','ALL',a.table_name, 'PROFILE_TEMPL_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\profile_templ_access_bck_agn.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPL_ACCESS_BCK_AGN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPL_ACCESS_BCK_AGN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROFILE_TEMPL_ACCESS_BCK_AGN ', 'ALL',a.table_name, 'PROFILE_TEMPL_ACCESS_BCK_AGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROFILE_TEMPL_ACCESS_BCK_AGN ','ALL',a.table_name, 'PROFILE_TEMPL_ACCESS_BCK_AGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\profile_templ_acc_func.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPL_ACC_FUNC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPL_ACC_FUNC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROFILE_TEMPL_ACC_FUNC ', 'ALL',a.table_name, 'PROFILE_TEMPL_ACC_FUNC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROFILE_TEMPL_ACC_FUNC ','ALL',a.table_name, 'PROFILE_TEMPL_ACC_FUNC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\profile_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROFILE_TEMPLATE ', 'ALL',a.table_name, 'PROFILE_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROFILE_TEMPLATE ','ALL',a.table_name, 'PROFILE_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\profile_template_bck_agn.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPLATE_BCK_AGN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROFILE_TEMPLATE_BCK_AGN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROFILE_TEMPLATE_BCK_AGN ', 'ALL',a.table_name, 'PROFILE_TEMPLATE_BCK_AGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROFILE_TEMPLATE_BCK_AGN ','ALL',a.table_name, 'PROFILE_TEMPLATE_BCK_AGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_in_out.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_IN_OUT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_IN_OUT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_IN_OUT ', 'ALL',a.table_name, 'PROF_IN_OUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_IN_OUT ','ALL',a.table_name, 'PROF_IN_OUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_institution.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_INSTITUTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_INSTITUTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_INSTITUTION ', 'ALL',a.table_name, 'PROF_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_INSTITUTION ','ALL',a.table_name, 'PROF_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_photo.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PHOTO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PHOTO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_PHOTO ', 'ALL',a.table_name, 'PROF_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_PHOTO ','ALL',a.table_name, 'PROF_PHOTO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_photo_medicomni.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PHOTO_MEDICOMNI','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PHOTO_MEDICOMNI','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_PHOTO_MEDICOMNI ', 'ALL',a.table_name, 'PROF_PHOTO_MEDICOMNI') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_PHOTO_MEDICOMNI ','ALL',a.table_name, 'PROF_PHOTO_MEDICOMNI') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_preferences.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PREFERENCES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PREFERENCES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_PREFERENCES ', 'ALL',a.table_name, 'PROF_PREFERENCES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_PREFERENCES ','ALL',a.table_name, 'PROF_PREFERENCES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_profile_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_PROFILE_TEMPLATE ', 'ALL',a.table_name, 'PROF_PROFILE_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_PROFILE_TEMPLATE ','ALL',a.table_name, 'PROF_PROFILE_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_ROOM ', 'ALL',a.table_name, 'PROF_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_ROOM ','ALL',a.table_name, 'PROF_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\prof_soft_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_SOFT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_SOFT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_SOFT_INST ', 'ALL',a.table_name, 'PROF_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_SOFT_INST ','ALL',a.table_name, 'PROF_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\prof_team.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_TEAM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_TEAM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_TEAM ', 'ALL',a.table_name, 'PROF_TEAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_TEAM ','ALL',a.table_name, 'PROF_TEAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\prof_team_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_TEAM_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROF_TEAM_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROF_TEAM_DET ', 'ALL',a.table_name, 'PROF_TEAM_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROF_TEAM_DET ','ALL',a.table_name, 'PROF_TEAM_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\protoc_diag.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROTOC_DIAG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROTOC_DIAG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROTOC_DIAG ', 'ALL',a.table_name, 'PROTOC_DIAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROTOC_DIAG ','ALL',a.table_name, 'PROTOC_DIAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\protocols.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','PROTOCOLS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','PROTOCOLS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('PROTOCOLS ', 'ALL',a.table_name, 'PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('PROTOCOLS ','ALL',a.table_name, 'PROTOCOLS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_doc_external.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOC_EXTERNAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOC_EXTERNAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_DOC_EXTERNAL ', 'ALL',a.table_name, 'P1_DOC_EXTERNAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_DOC_EXTERNAL ','ALL',a.table_name, 'P1_DOC_EXTERNAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_doc_external_request.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOC_EXTERNAL_REQUEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOC_EXTERNAL_REQUEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_DOC_EXTERNAL_REQUEST ', 'ALL',a.table_name, 'P1_DOC_EXTERNAL_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_DOC_EXTERNAL_REQUEST ','ALL',a.table_name, 'P1_DOC_EXTERNAL_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_documents.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOCUMENTS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOCUMENTS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_DOCUMENTS ', 'ALL',a.table_name, 'P1_DOCUMENTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_DOCUMENTS ','ALL',a.table_name, 'P1_DOCUMENTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_documents_done.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOCUMENTS_DONE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_DOCUMENTS_DONE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_DOCUMENTS_DONE ', 'ALL',a.table_name, 'P1_DOCUMENTS_DONE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_DOCUMENTS_DONE ','ALL',a.table_name, 'P1_DOCUMENTS_DONE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_external_request.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_EXTERNAL_REQUEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_EXTERNAL_REQUEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_EXTERNAL_REQUEST ', 'ALL',a.table_name, 'P1_EXTERNAL_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_EXTERNAL_REQUEST ','ALL',a.table_name, 'P1_EXTERNAL_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_ext_req_tracking.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_EXT_REQ_TRACKING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_EXT_REQ_TRACKING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_EXT_REQ_TRACKING ', 'ALL',a.table_name, 'P1_EXT_REQ_TRACKING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_EXT_REQ_TRACKING ','ALL',a.table_name, 'P1_EXT_REQ_TRACKING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_history.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_HISTORY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_HISTORY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_HISTORY ', 'ALL',a.table_name, 'P1_HISTORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_HISTORY ','ALL',a.table_name, 'P1_HISTORY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_prblm_rec_procedure.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_PRBLM_REC_PROCEDURE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_PRBLM_REC_PROCEDURE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_PRBLM_REC_PROCEDURE ', 'ALL',a.table_name, 'P1_PRBLM_REC_PROCEDURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_PRBLM_REC_PROCEDURE ','ALL',a.table_name, 'P1_PRBLM_REC_PROCEDURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\p1_problem.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_PROBLEM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_PROBLEM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_PROBLEM ', 'ALL',a.table_name, 'P1_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_PROBLEM ','ALL',a.table_name, 'P1_PROBLEM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\p1_problem_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_PROBLEM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_PROBLEM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_PROBLEM_DEP_CLIN_SERV ', 'ALL',a.table_name, 'P1_PROBLEM_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_PROBLEM_DEP_CLIN_SERV ','ALL',a.table_name, 'P1_PROBLEM_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\p1_recomended_procedure.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','P1_RECOMENDED_PROCEDURE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','P1_RECOMENDED_PROCEDURE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('P1_RECOMENDED_PROCEDURE ', 'ALL',a.table_name, 'P1_RECOMENDED_PROCEDURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('P1_RECOMENDED_PROCEDURE ','ALL',a.table_name, 'P1_RECOMENDED_PROCEDURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rb_interv_icd.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RB_INTERV_ICD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RB_INTERV_ICD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RB_INTERV_ICD ', 'ALL',a.table_name, 'RB_INTERV_ICD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RB_INTERV_ICD ','ALL',a.table_name, 'RB_INTERV_ICD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\rb_profile_templ_access.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RB_PROFILE_TEMPL_ACCESS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RB_PROFILE_TEMPL_ACCESS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RB_PROFILE_TEMPL_ACCESS ', 'ALL',a.table_name, 'RB_PROFILE_TEMPL_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RB_PROFILE_TEMPL_ACCESS ','ALL',a.table_name, 'RB_PROFILE_TEMPL_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rb_sys_button_prop.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RB_SYS_BUTTON_PROP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RB_SYS_BUTTON_PROP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RB_SYS_BUTTON_PROP ', 'ALL',a.table_name, 'RB_SYS_BUTTON_PROP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RB_SYS_BUTTON_PROP ','ALL',a.table_name, 'RB_SYS_BUTTON_PROP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rb_sys_button_prop2.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RB_SYS_BUTTON_PROP2','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RB_SYS_BUTTON_PROP2','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RB_SYS_BUTTON_PROP2 ', 'ALL',a.table_name, 'RB_SYS_BUTTON_PROP2') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RB_SYS_BUTTON_PROP2 ','ALL',a.table_name, 'RB_SYS_BUTTON_PROP2') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rb_sys_shortcut.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RB_SYS_SHORTCUT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RB_SYS_SHORTCUT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RB_SYS_SHORTCUT ', 'ALL',a.table_name, 'RB_SYS_SHORTCUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RB_SYS_SHORTCUT ','ALL',a.table_name, 'RB_SYS_SHORTCUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\recm.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RECM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RECM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RECM ', 'ALL',a.table_name, 'RECM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RECM ','ALL',a.table_name, 'RECM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\records_review.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RECORDS_REVIEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RECORDS_REVIEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RECORDS_REVIEW ', 'ALL',a.table_name, 'RECORDS_REVIEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RECORDS_REVIEW ','ALL',a.table_name, 'RECORDS_REVIEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\records_review_read.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RECORDS_REVIEW_READ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RECORDS_REVIEW_READ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RECORDS_REVIEW_READ ', 'ALL',a.table_name, 'RECORDS_REVIEW_READ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RECORDS_REVIEW_READ ','ALL',a.table_name, 'RECORDS_REVIEW_READ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\religion.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RELIGION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RELIGION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RELIGION ', 'ALL',a.table_name, 'RELIGION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RELIGION ','ALL',a.table_name, 'RELIGION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rep_destination.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_DESTINATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_DESTINATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_DESTINATION ', 'ALL',a.table_name, 'REP_DESTINATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_DESTINATION ','ALL',a.table_name, 'REP_DESTINATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\reports.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REPORTS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REPORTS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REPORTS ', 'ALL',a.table_name, 'REPORTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REPORTS ','ALL',a.table_name, 'REPORTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\reports_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REPORTS_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REPORTS_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REPORTS_GROUP ', 'ALL',a.table_name, 'REPORTS_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REPORTS_GROUP ','ALL',a.table_name, 'REPORTS_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\rep_prof_exception.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROF_EXCEPTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROF_EXCEPTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_PROF_EXCEPTION ', 'ALL',a.table_name, 'REP_PROF_EXCEPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_PROF_EXCEPTION ','ALL',a.table_name, 'REP_PROF_EXCEPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rep_profile_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_PROFILE_TEMPLATE ', 'ALL',a.table_name, 'REP_PROFILE_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_PROFILE_TEMPLATE ','ALL',a.table_name, 'REP_PROFILE_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\rep_profile_template_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROFILE_TEMPLATE_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROFILE_TEMPLATE_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_PROFILE_TEMPLATE_DET ', 'ALL',a.table_name, 'REP_PROFILE_TEMPLATE_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_PROFILE_TEMPLATE_DET ','ALL',a.table_name, 'REP_PROFILE_TEMPLATE_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rep_prof_templ_access.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROF_TEMPL_ACCESS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROF_TEMPL_ACCESS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_PROF_TEMPL_ACCESS ', 'ALL',a.table_name, 'REP_PROF_TEMPL_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_PROF_TEMPL_ACCESS ','ALL',a.table_name, 'REP_PROF_TEMPL_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rep_prof_template.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROF_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_PROF_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_PROF_TEMPLATE ', 'ALL',a.table_name, 'REP_PROF_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_PROF_TEMPLATE ','ALL',a.table_name, 'REP_PROF_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rep_screen.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_SCREEN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_SCREEN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_SCREEN ', 'ALL',a.table_name, 'REP_SCREEN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_SCREEN ','ALL',a.table_name, 'REP_SCREEN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rep_section.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_SECTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_SECTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_SECTION ', 'ALL',a.table_name, 'REP_SECTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_SECTION ','ALL',a.table_name, 'REP_SECTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rep_section_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','REP_SECTION_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','REP_SECTION_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('REP_SECTION_DET ', 'ALL',a.table_name, 'REP_SECTION_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('REP_SECTION_DET ','ALL',a.table_name, 'REP_SECTION_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\result_status.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','RESULT_STATUS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','RESULT_STATUS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('RESULT_STATUS ', 'ALL',a.table_name, 'RESULT_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('RESULT_STATUS ','ALL',a.table_name, 'RESULT_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ROOM ', 'ALL',a.table_name, 'ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ROOM ','ALL',a.table_name, 'ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\room_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ROOM_DEP_CLIN_SERV ', 'ALL',a.table_name, 'ROOM_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ROOM_DEP_CLIN_SERV ','ALL',a.table_name, 'ROOM_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\room_dep_position.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_DEP_POSITION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_DEP_POSITION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ROOM_DEP_POSITION ', 'ALL',a.table_name, 'ROOM_DEP_POSITION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ROOM_DEP_POSITION ','ALL',a.table_name, 'ROOM_DEP_POSITION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\room_ext_sys.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_EXT_SYS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_EXT_SYS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ROOM_EXT_SYS ', 'ALL',a.table_name, 'ROOM_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ROOM_EXT_SYS ','ALL',a.table_name, 'ROOM_EXT_SYS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\room_scheduled.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_SCHEDULED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ROOM_SCHEDULED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ROOM_SCHEDULED ', 'ALL',a.table_name, 'ROOM_SCHEDULED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ROOM_SCHEDULED ','ALL',a.table_name, 'ROOM_SCHEDULED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\rotation_interval.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','ROTATION_INTERVAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','ROTATION_INTERVAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('ROTATION_INTERVAL ', 'ALL',a.table_name, 'ROTATION_INTERVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('ROTATION_INTERVAL ','ALL',a.table_name, 'ROTATION_INTERVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sample_recipient.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_RECIPIENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_RECIPIENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_RECIPIENT ', 'ALL',a.table_name, 'SAMPLE_RECIPIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_RECIPIENT ','ALL',a.table_name, 'SAMPLE_RECIPIENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_text.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TEXT ', 'ALL',a.table_name, 'SAMPLE_TEXT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TEXT ','ALL',a.table_name, 'SAMPLE_TEXT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_text_bck.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TEXT_BCK ', 'ALL',a.table_name, 'SAMPLE_TEXT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TEXT_BCK ','ALL',a.table_name, 'SAMPLE_TEXT_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_text_freq.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_FREQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_FREQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TEXT_FREQ ', 'ALL',a.table_name, 'SAMPLE_TEXT_FREQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TEXT_FREQ ','ALL',a.table_name, 'SAMPLE_TEXT_FREQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_text_freq_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_FREQ_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_FREQ_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TEXT_FREQ_BCK ', 'ALL',a.table_name, 'SAMPLE_TEXT_FREQ_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TEXT_FREQ_BCK ','ALL',a.table_name, 'SAMPLE_TEXT_FREQ_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_text_prof.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_PROF','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_PROF','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TEXT_PROF ', 'ALL',a.table_name, 'SAMPLE_TEXT_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TEXT_PROF ','ALL',a.table_name, 'SAMPLE_TEXT_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_text_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TEXT_TYPE ', 'ALL',a.table_name, 'SAMPLE_TEXT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TEXT_TYPE ','ALL',a.table_name, 'SAMPLE_TEXT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_text_type_cat.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_TYPE_CAT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TEXT_TYPE_CAT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TEXT_TYPE_CAT ', 'ALL',a.table_name, 'SAMPLE_TEXT_TYPE_CAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TEXT_TYPE_CAT ','ALL',a.table_name, 'SAMPLE_TEXT_TYPE_CAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sample_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SAMPLE_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SAMPLE_TYPE ', 'ALL',a.table_name, 'SAMPLE_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SAMPLE_TYPE ','ALL',a.table_name, 'SAMPLE_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\scales.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCALES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCALES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCALES ', 'ALL',a.table_name, 'SCALES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCALES ','ALL',a.table_name, 'SCALES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\scales_class.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCALES_CLASS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCALES_CLASS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCALES_CLASS ', 'ALL',a.table_name, 'SCALES_CLASS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCALES_CLASS ','ALL',a.table_name, 'SCALES_CLASS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\scales_doc_value.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCALES_DOC_VALUE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCALES_DOC_VALUE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCALES_DOC_VALUE ', 'ALL',a.table_name, 'SCALES_DOC_VALUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCALES_DOC_VALUE ','ALL',a.table_name, 'SCALES_DOC_VALUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_action.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_ACTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_ACTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_ACTION ', 'ALL',a.table_name, 'SCH_ACTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_ACTION ','ALL',a.table_name, 'SCH_ACTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sch_cancel_reason.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CANCEL_REASON','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CANCEL_REASON','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_CANCEL_REASON ', 'ALL',a.table_name, 'SCH_CANCEL_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_CANCEL_REASON ','ALL',a.table_name, 'SCH_CANCEL_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_cancel_reason_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CANCEL_REASON_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CANCEL_REASON_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_CANCEL_REASON_INST ', 'ALL',a.table_name, 'SCH_CANCEL_REASON_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_CANCEL_REASON_INST ','ALL',a.table_name, 'SCH_CANCEL_REASON_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_consult_vacancy.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CONSULT_VACANCY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CONSULT_VACANCY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_CONSULT_VACANCY ', 'ALL',a.table_name, 'SCH_CONSULT_VACANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_CONSULT_VACANCY ','ALL',a.table_name, 'SCH_CONSULT_VACANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_consult_vacancy_temp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CONSULT_VACANCY_TEMP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_CONSULT_VACANCY_TEMP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_CONSULT_VACANCY_TEMP ', 'ALL',a.table_name, 'SCH_CONSULT_VACANCY_TEMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_CONSULT_VACANCY_TEMP ','ALL',a.table_name, 'SCH_CONSULT_VACANCY_TEMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_default_consult_vacancy.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_DEFAULT_CONSULT_VACANCY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_DEFAULT_CONSULT_VACANCY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_DEFAULT_CONSULT_VACANCY ', 'ALL',a.table_name, 'SCH_DEFAULT_CONSULT_VACANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_DEFAULT_CONSULT_VACANCY ','ALL',a.table_name, 'SCH_DEFAULT_CONSULT_VACANCY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\schedule.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCHEDULE ', 'ALL',a.table_name, 'SCHEDULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCHEDULE ','ALL',a.table_name, 'SCHEDULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\schedule_alter.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_ALTER','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_ALTER','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCHEDULE_ALTER ', 'ALL',a.table_name, 'SCHEDULE_ALTER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCHEDULE_ALTER ','ALL',a.table_name, 'SCHEDULE_ALTER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\schedule_outp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_OUTP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_OUTP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCHEDULE_OUTP ', 'ALL',a.table_name, 'SCHEDULE_OUTP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCHEDULE_OUTP ','ALL',a.table_name, 'SCHEDULE_OUTP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\schedule_sr.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_SR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_SR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCHEDULE_SR ', 'ALL',a.table_name, 'SCHEDULE_SR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCHEDULE_SR ','ALL',a.table_name, 'SCHEDULE_SR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\schedule_sr_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_SR_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCHEDULE_SR_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCHEDULE_SR_DET ', 'ALL',a.table_name, 'SCHEDULE_SR_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCHEDULE_SR_DET ','ALL',a.table_name, 'SCHEDULE_SR_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_event.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_EVENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_EVENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_EVENT ', 'ALL',a.table_name, 'SCH_EVENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_EVENT ','ALL',a.table_name, 'SCH_EVENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sch_event_dcs.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_EVENT_DCS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_EVENT_DCS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_EVENT_DCS ', 'ALL',a.table_name, 'SCH_EVENT_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_EVENT_DCS ','ALL',a.table_name, 'SCH_EVENT_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_event_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_EVENT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_EVENT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_EVENT_INST ', 'ALL',a.table_name, 'SCH_EVENT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_EVENT_INST ','ALL',a.table_name, 'SCH_EVENT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sch_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_GROUP ', 'ALL',a.table_name, 'SCH_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_GROUP ','ALL',a.table_name, 'SCH_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_log.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_LOG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_LOG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_LOG ', 'ALL',a.table_name, 'SCH_LOG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_LOG ','ALL',a.table_name, 'SCH_LOG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\scholarship.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCHOLARSHIP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCHOLARSHIP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCHOLARSHIP ', 'ALL',a.table_name, 'SCHOLARSHIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCHOLARSHIP ','ALL',a.table_name, 'SCHOLARSHIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\school.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCHOOL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCHOOL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCHOOL ', 'ALL',a.table_name, 'SCHOOL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCHOOL ','ALL',a.table_name, 'SCHOOL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_permission.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_PERMISSION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_PERMISSION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_PERMISSION ', 'ALL',a.table_name, 'SCH_PERMISSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_PERMISSION ','ALL',a.table_name, 'SCH_PERMISSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_permission_temp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_PERMISSION_TEMP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_PERMISSION_TEMP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_PERMISSION_TEMP ', 'ALL',a.table_name, 'SCH_PERMISSION_TEMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_PERMISSION_TEMP ','ALL',a.table_name, 'SCH_PERMISSION_TEMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_prof_outp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_PROF_OUTP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_PROF_OUTP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_PROF_OUTP ', 'ALL',a.table_name, 'SCH_PROF_OUTP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_PROF_OUTP ','ALL',a.table_name, 'SCH_PROF_OUTP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_resource.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_RESOURCE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_RESOURCE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_RESOURCE ', 'ALL',a.table_name, 'SCH_RESOURCE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_RESOURCE ','ALL',a.table_name, 'SCH_RESOURCE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_schedule_request.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_SCHEDULE_REQUEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_SCHEDULE_REQUEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_SCHEDULE_REQUEST ', 'ALL',a.table_name, 'SCH_SCHEDULE_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_SCHEDULE_REQUEST ','ALL',a.table_name, 'SCH_SCHEDULE_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sch_service.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_SERVICE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_SERVICE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_SERVICE ', 'ALL',a.table_name, 'SCH_SERVICE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_SERVICE ','ALL',a.table_name, 'SCH_SERVICE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_service_dcs.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_SERVICE_DCS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCH_SERVICE_DCS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_SERVICE_DCS ', 'ALL',a.table_name, 'SCH_SERVICE_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_SERVICE_DCS ','ALL',a.table_name, 'SCH_SERVICE_DCS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\screen_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SCREEN_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SCREEN_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCREEN_TEMPLATE ', 'ALL',a.table_name, 'SCREEN_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCREEN_TEMPLATE ','ALL',a.table_name, 'SCREEN_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\serv_sched_access.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SERV_SCHED_ACCESS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SERV_SCHED_ACCESS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SERV_SCHED_ACCESS ', 'ALL',a.table_name, 'SERV_SCHED_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SERV_SCHED_ACCESS ','ALL',a.table_name, 'SERV_SCHED_ACCESS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\slot.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SLOT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SLOT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SLOT ', 'ALL',a.table_name, 'SLOT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SLOT ','ALL',a.table_name, 'SLOT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\snomed_concepts.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SNOMED_CONCEPTS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SNOMED_CONCEPTS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SNOMED_CONCEPTS ', 'ALL',a.table_name, 'SNOMED_CONCEPTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SNOMED_CONCEPTS ','ALL',a.table_name, 'SNOMED_CONCEPTS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\snomed_descriptions.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SNOMED_DESCRIPTIONS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SNOMED_DESCRIPTIONS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SNOMED_DESCRIPTIONS ', 'ALL',a.table_name, 'SNOMED_DESCRIPTIONS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SNOMED_DESCRIPTIONS ','ALL',a.table_name, 'SNOMED_DESCRIPTIONS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\snomed_relationships.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SNOMED_RELATIONSHIPS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SNOMED_RELATIONSHIPS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SNOMED_RELATIONSHIPS ', 'ALL',a.table_name, 'SNOMED_RELATIONSHIPS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SNOMED_RELATIONSHIPS ','ALL',a.table_name, 'SNOMED_RELATIONSHIPS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\social_class.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_CLASS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_CLASS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_CLASS ', 'ALL',a.table_name, 'SOCIAL_CLASS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_CLASS ','ALL',a.table_name, 'SOCIAL_CLASS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\social_diagnosis.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_DIAGNOSIS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_DIAGNOSIS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_DIAGNOSIS ', 'ALL',a.table_name, 'SOCIAL_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_DIAGNOSIS ','ALL',a.table_name, 'SOCIAL_DIAGNOSIS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\social_epis_diag.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_DIAG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_DIAG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_EPIS_DIAG ', 'ALL',a.table_name, 'SOCIAL_EPIS_DIAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_EPIS_DIAG ','ALL',a.table_name, 'SOCIAL_EPIS_DIAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\social_epis_discharge.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_DISCHARGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_DISCHARGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_EPIS_DISCHARGE ', 'ALL',a.table_name, 'SOCIAL_EPIS_DISCHARGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_EPIS_DISCHARGE ','ALL',a.table_name, 'SOCIAL_EPIS_DISCHARGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\social_epis_interv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_INTERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_INTERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_EPIS_INTERV ', 'ALL',a.table_name, 'SOCIAL_EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_EPIS_INTERV ','ALL',a.table_name, 'SOCIAL_EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\social_episode.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPISODE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPISODE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_EPISODE ', 'ALL',a.table_name, 'SOCIAL_EPISODE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_EPISODE ','ALL',a.table_name, 'SOCIAL_EPISODE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\social_epis_request.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_REQUEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_REQUEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_EPIS_REQUEST ', 'ALL',a.table_name, 'SOCIAL_EPIS_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_EPIS_REQUEST ','ALL',a.table_name, 'SOCIAL_EPIS_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\social_epis_situation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_SITUATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_SITUATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_EPIS_SITUATION ', 'ALL',a.table_name, 'SOCIAL_EPIS_SITUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_EPIS_SITUATION ','ALL',a.table_name, 'SOCIAL_EPIS_SITUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\social_epis_solution.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_SOLUTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_EPIS_SOLUTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_EPIS_SOLUTION ', 'ALL',a.table_name, 'SOCIAL_EPIS_SOLUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_EPIS_SOLUTION ','ALL',a.table_name, 'SOCIAL_EPIS_SOLUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\social_intervention.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_INTERVENTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOCIAL_INTERVENTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOCIAL_INTERVENTION ', 'ALL',a.table_name, 'SOCIAL_INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOCIAL_INTERVENTION ','ALL',a.table_name, 'SOCIAL_INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\soft_inst_impl.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOFT_INST_IMPL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOFT_INST_IMPL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOFT_INST_IMPL ', 'ALL',a.table_name, 'SOFT_INST_IMPL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOFT_INST_IMPL ','ALL',a.table_name, 'SOFT_INST_IMPL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\soft_inst_services.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOFT_INST_SERVICES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOFT_INST_SERVICES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOFT_INST_SERVICES ', 'ALL',a.table_name, 'SOFT_INST_SERVICES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOFT_INST_SERVICES ','ALL',a.table_name, 'SOFT_INST_SERVICES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\soft_lang.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOFT_LANG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOFT_LANG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOFT_LANG ', 'ALL',a.table_name, 'SOFT_LANG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOFT_LANG ','ALL',a.table_name, 'SOFT_LANG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\software.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOFTWARE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOFTWARE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOFTWARE ', 'ALL',a.table_name, 'SOFTWARE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOFTWARE ','ALL',a.table_name, 'SOFTWARE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\software_dept.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOFTWARE_DEPT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOFTWARE_DEPT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOFTWARE_DEPT ', 'ALL',a.table_name, 'SOFTWARE_DEPT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOFTWARE_DEPT ','ALL',a.table_name, 'SOFTWARE_DEPT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\software_institution.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SOFTWARE_INSTITUTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SOFTWARE_INSTITUTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SOFTWARE_INSTITUTION ', 'ALL',a.table_name, 'SOFTWARE_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SOFTWARE_INSTITUTION ','ALL',a.table_name, 'SOFTWARE_INSTITUTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\speciality.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SPECIALITY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SPECIALITY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SPECIALITY ', 'ALL',a.table_name, 'SPECIALITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SPECIALITY ','ALL',a.table_name, 'SPECIALITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\spec_sys_appar.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SPEC_SYS_APPAR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SPEC_SYS_APPAR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SPEC_SYS_APPAR ', 'ALL',a.table_name, 'SPEC_SYS_APPAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SPEC_SYS_APPAR ','ALL',a.table_name, 'SPEC_SYS_APPAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sqln_explain_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SQLN_EXPLAIN_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SQLN_EXPLAIN_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SQLN_EXPLAIN_PLAN ', 'ALL',a.table_name, 'SQLN_EXPLAIN_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SQLN_EXPLAIN_PLAN ','ALL',a.table_name, 'SQLN_EXPLAIN_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_base_diag.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_BASE_DIAG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_BASE_DIAG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_BASE_DIAG ', 'ALL',a.table_name, 'SR_BASE_DIAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_BASE_DIAG ','ALL',a.table_name, 'SR_BASE_DIAG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_cancel_reason.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CANCEL_REASON','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CANCEL_REASON','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_CANCEL_REASON ', 'ALL',a.table_name, 'SR_CANCEL_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_CANCEL_REASON ','ALL',a.table_name, 'SR_CANCEL_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_chklist.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CHKLIST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CHKLIST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_CHKLIST ', 'ALL',a.table_name, 'SR_CHKLIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_CHKLIST ','ALL',a.table_name, 'SR_CHKLIST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_chklist_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CHKLIST_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CHKLIST_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_CHKLIST_DET ', 'ALL',a.table_name, 'SR_CHKLIST_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_CHKLIST_DET ','ALL',a.table_name, 'SR_CHKLIST_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_chklist_manual.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CHKLIST_MANUAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_CHKLIST_MANUAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_CHKLIST_MANUAL ', 'ALL',a.table_name, 'SR_CHKLIST_MANUAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_CHKLIST_MANUAL ','ALL',a.table_name, 'SR_CHKLIST_MANUAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_doc_element.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_DOC_ELEMENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_DOC_ELEMENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_DOC_ELEMENT ', 'ALL',a.table_name, 'SR_DOC_ELEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_DOC_ELEMENT ','ALL',a.table_name, 'SR_DOC_ELEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_doc_element_crit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_DOC_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_DOC_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_DOC_ELEMENT_CRIT ', 'ALL',a.table_name, 'SR_DOC_ELEMENT_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_DOC_ELEMENT_CRIT ','ALL',a.table_name, 'SR_DOC_ELEMENT_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_epis_interv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EPIS_INTERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EPIS_INTERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EPIS_INTERV ', 'ALL',a.table_name, 'SR_EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EPIS_INTERV ','ALL',a.table_name, 'SR_EPIS_INTERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_epis_interv_desc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EPIS_INTERV_DESC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EPIS_INTERV_DESC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EPIS_INTERV_DESC ', 'ALL',a.table_name, 'SR_EPIS_INTERV_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EPIS_INTERV_DESC ','ALL',a.table_name, 'SR_EPIS_INTERV_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_equip.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EQUIP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EQUIP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EQUIP ', 'ALL',a.table_name, 'SR_EQUIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EQUIP ','ALL',a.table_name, 'SR_EQUIP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_equip_kit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EQUIP_KIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EQUIP_KIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EQUIP_KIT ', 'ALL',a.table_name, 'SR_EQUIP_KIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EQUIP_KIT ','ALL',a.table_name, 'SR_EQUIP_KIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_equip_period.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EQUIP_PERIOD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EQUIP_PERIOD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EQUIP_PERIOD ', 'ALL',a.table_name, 'SR_EQUIP_PERIOD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EQUIP_PERIOD ','ALL',a.table_name, 'SR_EQUIP_PERIOD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sr_eval_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EVAL_DET ', 'ALL',a.table_name, 'SR_EVAL_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EVAL_DET ','ALL',a.table_name, 'SR_EVAL_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_eval_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EVAL_NOTES ', 'ALL',a.table_name, 'SR_EVAL_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EVAL_NOTES ','ALL',a.table_name, 'SR_EVAL_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_eval_rule.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_RULE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_RULE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EVAL_RULE ', 'ALL',a.table_name, 'SR_EVAL_RULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EVAL_RULE ','ALL',a.table_name, 'SR_EVAL_RULE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_eval_summ.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_SUMM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_SUMM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EVAL_SUMM ', 'ALL',a.table_name, 'SR_EVAL_SUMM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EVAL_SUMM ','ALL',a.table_name, 'SR_EVAL_SUMM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_eval_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EVAL_TYPE ', 'ALL',a.table_name, 'SR_EVAL_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EVAL_TYPE ','ALL',a.table_name, 'SR_EVAL_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_evaluation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVALUATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVALUATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EVALUATION ', 'ALL',a.table_name, 'SR_EVALUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EVALUATION ','ALL',a.table_name, 'SR_EVALUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_eval_visit.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_VISIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_EVAL_VISIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_EVAL_VISIT ', 'ALL',a.table_name, 'SR_EVAL_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_EVAL_VISIT ','ALL',a.table_name, 'SR_EVAL_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_interv_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_INTERV_DEP_CLIN_SERV ', 'ALL',a.table_name, 'SR_INTERV_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_INTERV_DEP_CLIN_SERV ','ALL',a.table_name, 'SR_INTERV_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_interv_desc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_DESC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_DESC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_INTERV_DESC ', 'ALL',a.table_name, 'SR_INTERV_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_INTERV_DESC ','ALL',a.table_name, 'SR_INTERV_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_intervention.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERVENTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERVENTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_INTERVENTION ', 'ALL',a.table_name, 'SR_INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_INTERVENTION ','ALL',a.table_name, 'SR_INTERVENTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_interv_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_INTERV_GROUP ', 'ALL',a.table_name, 'SR_INTERV_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_INTERV_GROUP ','ALL',a.table_name, 'SR_INTERV_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_interv_group_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_GROUP_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_INTERV_GROUP_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_INTERV_GROUP_DET ', 'ALL',a.table_name, 'SR_INTERV_GROUP_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_INTERV_GROUP_DET ','ALL',a.table_name, 'SR_INTERV_GROUP_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_nurse_rec.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_NURSE_REC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_NURSE_REC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_NURSE_REC ', 'ALL',a.table_name, 'SR_NURSE_REC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_NURSE_REC ','ALL',a.table_name, 'SR_NURSE_REC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sr_pat_status.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PAT_STATUS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PAT_STATUS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PAT_STATUS ', 'ALL',a.table_name, 'SR_PAT_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PAT_STATUS ','ALL',a.table_name, 'SR_PAT_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_pat_status_notes.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PAT_STATUS_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PAT_STATUS_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PAT_STATUS_NOTES ', 'ALL',a.table_name, 'SR_PAT_STATUS_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PAT_STATUS_NOTES ','ALL',a.table_name, 'SR_PAT_STATUS_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_pat_status_period.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PAT_STATUS_PERIOD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PAT_STATUS_PERIOD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PAT_STATUS_PERIOD ', 'ALL',a.table_name, 'SR_PAT_STATUS_PERIOD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PAT_STATUS_PERIOD ','ALL',a.table_name, 'SR_PAT_STATUS_PERIOD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_pos_eval_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POS_EVAL_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POS_EVAL_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_POS_EVAL_DET ', 'ALL',a.table_name, 'SR_POS_EVAL_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_POS_EVAL_DET ','ALL',a.table_name, 'SR_POS_EVAL_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_pos_eval_visit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POS_EVAL_VISIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POS_EVAL_VISIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_POS_EVAL_VISIT ', 'ALL',a.table_name, 'SR_POS_EVAL_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_POS_EVAL_VISIT ','ALL',a.table_name, 'SR_POS_EVAL_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_posit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POSIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POSIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_POSIT ', 'ALL',a.table_name, 'SR_POSIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_POSIT ','ALL',a.table_name, 'SR_POSIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_posit_req.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POSIT_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_POSIT_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_POSIT_REQ ', 'ALL',a.table_name, 'SR_POSIT_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_POSIT_REQ ','ALL',a.table_name, 'SR_POSIT_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_pre_anest.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_ANEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_ANEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PRE_ANEST ', 'ALL',a.table_name, 'SR_PRE_ANEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PRE_ANEST ','ALL',a.table_name, 'SR_PRE_ANEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_pre_anest_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_ANEST_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_ANEST_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PRE_ANEST_DET ', 'ALL',a.table_name, 'SR_PRE_ANEST_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PRE_ANEST_DET ','ALL',a.table_name, 'SR_PRE_ANEST_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_pre_eval.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_EVAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_EVAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PRE_EVAL ', 'ALL',a.table_name, 'SR_PRE_EVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PRE_EVAL ','ALL',a.table_name, 'SR_PRE_EVAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_pre_eval_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_EVAL_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_EVAL_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PRE_EVAL_DET ', 'ALL',a.table_name, 'SR_PRE_EVAL_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PRE_EVAL_DET ','ALL',a.table_name, 'SR_PRE_EVAL_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_pre_eval_visit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_EVAL_VISIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PRE_EVAL_VISIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PRE_EVAL_VISIT ', 'ALL',a.table_name, 'SR_PRE_EVAL_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PRE_EVAL_VISIT ','ALL',a.table_name, 'SR_PRE_EVAL_VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_prof_recov_schd.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PROF_RECOV_SCHD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PROF_RECOV_SCHD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PROF_RECOV_SCHD ', 'ALL',a.table_name, 'SR_PROF_RECOV_SCHD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PROF_RECOV_SCHD ','ALL',a.table_name, 'SR_PROF_RECOV_SCHD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sr_prof_shift.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PROF_SHIFT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PROF_SHIFT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PROF_SHIFT ', 'ALL',a.table_name, 'SR_PROF_SHIFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PROF_SHIFT ','ALL',a.table_name, 'SR_PROF_SHIFT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_prof_team_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PROF_TEAM_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_PROF_TEAM_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_PROF_TEAM_DET ', 'ALL',a.table_name, 'SR_PROF_TEAM_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_PROF_TEAM_DET ','ALL',a.table_name, 'SR_PROF_TEAM_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_receive.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_RECEIVE ', 'ALL',a.table_name, 'SR_RECEIVE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_RECEIVE ','ALL',a.table_name, 'SR_RECEIVE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_receive_manual.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_MANUAL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_MANUAL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_RECEIVE_MANUAL ', 'ALL',a.table_name, 'SR_RECEIVE_MANUAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_RECEIVE_MANUAL ','ALL',a.table_name, 'SR_RECEIVE_MANUAL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_receive_proc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_PROC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_PROC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_RECEIVE_PROC ', 'ALL',a.table_name, 'SR_RECEIVE_PROC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_RECEIVE_PROC ','ALL',a.table_name, 'SR_RECEIVE_PROC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_receive_proc_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_PROC_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_PROC_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_RECEIVE_PROC_DET ', 'ALL',a.table_name, 'SR_RECEIVE_PROC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_RECEIVE_PROC_DET ','ALL',a.table_name, 'SR_RECEIVE_PROC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_receive_proc_notes.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_PROC_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RECEIVE_PROC_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_RECEIVE_PROC_NOTES ', 'ALL',a.table_name, 'SR_RECEIVE_PROC_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_RECEIVE_PROC_NOTES ','ALL',a.table_name, 'SR_RECEIVE_PROC_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_reserv_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RESERV_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_RESERV_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_RESERV_REQ ', 'ALL',a.table_name, 'SR_RESERV_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_RESERV_REQ ','ALL',a.table_name, 'SR_RESERV_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_room_status.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_ROOM_STATUS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_ROOM_STATUS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_ROOM_STATUS ', 'ALL',a.table_name, 'SR_ROOM_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_ROOM_STATUS ','ALL',a.table_name, 'SR_ROOM_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_surgery_rec_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_REC_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_REC_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURGERY_REC_DET ', 'ALL',a.table_name, 'SR_SURGERY_REC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURGERY_REC_DET ','ALL',a.table_name, 'SR_SURGERY_REC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_surgery_record.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_RECORD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_RECORD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURGERY_RECORD ', 'ALL',a.table_name, 'SR_SURGERY_RECORD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURGERY_RECORD ','ALL',a.table_name, 'SR_SURGERY_RECORD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_surgery_time.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_TIME','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_TIME','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURGERY_TIME ', 'ALL',a.table_name, 'SR_SURGERY_TIME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURGERY_TIME ','ALL',a.table_name, 'SR_SURGERY_TIME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_surgery_time_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_TIME_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURGERY_TIME_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURGERY_TIME_DET ', 'ALL',a.table_name, 'SR_SURGERY_TIME_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURGERY_TIME_DET ','ALL',a.table_name, 'SR_SURGERY_TIME_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sr_surg_period.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PERIOD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PERIOD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURG_PERIOD ', 'ALL',a.table_name, 'SR_SURG_PERIOD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURG_PERIOD ','ALL',a.table_name, 'SR_SURG_PERIOD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_surg_prot_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROT_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROT_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURG_PROT_DET ', 'ALL',a.table_name, 'SR_SURG_PROT_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURG_PROT_DET ','ALL',a.table_name, 'SR_SURG_PROT_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_surg_protocol.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROTOCOL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROTOCOL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURG_PROTOCOL ', 'ALL',a.table_name, 'SR_SURG_PROTOCOL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURG_PROTOCOL ','ALL',a.table_name, 'SR_SURG_PROTOCOL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_surg_prot_task.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROT_TASK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROT_TASK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURG_PROT_TASK ', 'ALL',a.table_name, 'SR_SURG_PROT_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURG_PROT_TASK ','ALL',a.table_name, 'SR_SURG_PROT_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sr_surg_prot_task_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROT_TASK_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_PROT_TASK_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURG_PROT_TASK_DET ', 'ALL',a.table_name, 'SR_SURG_PROT_TASK_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURG_PROT_TASK_DET ','ALL',a.table_name, 'SR_SURG_PROT_TASK_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sr_surg_task.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_TASK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SR_SURG_TASK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SR_SURG_TASK ', 'ALL',a.table_name, 'SR_SURG_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SR_SURG_TASK ','ALL',a.table_name, 'SR_SURG_TASK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_alert.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ALERT ', 'ALL',a.table_name, 'SYS_ALERT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ALERT ','ALL',a.table_name, 'SYS_ALERT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_alert_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ALERT_DET ', 'ALL',a.table_name, 'SYS_ALERT_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ALERT_DET ','ALL',a.table_name, 'SYS_ALERT_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_alert_prof.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_PROF','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_PROF','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ALERT_PROF ', 'ALL',a.table_name, 'SYS_ALERT_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ALERT_PROF ','ALL',a.table_name, 'SYS_ALERT_PROF') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_alert_profile.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_PROFILE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_PROFILE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ALERT_PROFILE ', 'ALL',a.table_name, 'SYS_ALERT_PROFILE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ALERT_PROFILE ','ALL',a.table_name, 'SYS_ALERT_PROFILE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_alert_software.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_SOFTWARE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_SOFTWARE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ALERT_SOFTWARE ', 'ALL',a.table_name, 'SYS_ALERT_SOFTWARE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ALERT_SOFTWARE ','ALL',a.table_name, 'SYS_ALERT_SOFTWARE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_alert_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ALERT_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ALERT_TYPE ', 'ALL',a.table_name, 'SYS_ALERT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ALERT_TYPE ','ALL',a.table_name, 'SYS_ALERT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_appar_organ.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_APPAR_ORGAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_APPAR_ORGAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_APPAR_ORGAN ', 'ALL',a.table_name, 'SYS_APPAR_ORGAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_APPAR_ORGAN ','ALL',a.table_name, 'SYS_APPAR_ORGAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sys_application_area.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_APPLICATION_AREA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_APPLICATION_AREA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_APPLICATION_AREA ', 'ALL',a.table_name, 'SYS_APPLICATION_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_APPLICATION_AREA ','ALL',a.table_name, 'SYS_APPLICATION_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_application_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_APPLICATION_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_APPLICATION_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_APPLICATION_TYPE ', 'ALL',a.table_name, 'SYS_APPLICATION_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_APPLICATION_TYPE ','ALL',a.table_name, 'SYS_APPLICATION_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sys_btn_crit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BTN_CRIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BTN_CRIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_BTN_CRIT ', 'ALL',a.table_name, 'SYS_BTN_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_BTN_CRIT ','ALL',a.table_name, 'SYS_BTN_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_btn_sbg.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BTN_SBG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BTN_SBG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_BTN_SBG ', 'ALL',a.table_name, 'SYS_BTN_SBG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_BTN_SBG ','ALL',a.table_name, 'SYS_BTN_SBG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sys_button.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BUTTON','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BUTTON','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_BUTTON ', 'ALL',a.table_name, 'SYS_BUTTON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_BUTTON ','ALL',a.table_name, 'SYS_BUTTON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_button_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BUTTON_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BUTTON_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_BUTTON_GROUP ', 'ALL',a.table_name, 'SYS_BUTTON_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_BUTTON_GROUP ','ALL',a.table_name, 'SYS_BUTTON_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_button_prop.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BUTTON_PROP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_BUTTON_PROP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_BUTTON_PROP ', 'ALL',a.table_name, 'SYS_BUTTON_PROP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_BUTTON_PROP ','ALL',a.table_name, 'SYS_BUTTON_PROP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_config.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_CONFIG','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_CONFIG','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_CONFIG ', 'ALL',a.table_name, 'SYS_CONFIG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_CONFIG ','ALL',a.table_name, 'SYS_CONFIG') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_documentation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_DOCUMENTATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_DOCUMENTATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_DOCUMENTATION ', 'ALL',a.table_name, 'SYS_DOCUMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_DOCUMENTATION ','ALL',a.table_name, 'SYS_DOCUMENTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_domain.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_DOMAIN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_DOMAIN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_DOMAIN ', 'ALL',a.table_name, 'SYS_DOMAIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_DOMAIN ','ALL',a.table_name, 'SYS_DOMAIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_element.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ELEMENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ELEMENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ELEMENT ', 'ALL',a.table_name, 'SYS_ELEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ELEMENT ','ALL',a.table_name, 'SYS_ELEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_element_crit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ELEMENT_CRIT ', 'ALL',a.table_name, 'SYS_ELEMENT_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ELEMENT_CRIT ','ALL',a.table_name, 'SYS_ELEMENT_CRIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_entrance.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ENTRANCE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ENTRANCE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ENTRANCE ', 'ALL',a.table_name, 'SYS_ENTRANCE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ENTRANCE ','ALL',a.table_name, 'SYS_ENTRANCE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sys_error.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ERROR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_ERROR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_ERROR ', 'ALL',a.table_name, 'SYS_ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_ERROR ','ALL',a.table_name, 'SYS_ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_field.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_FIELD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_FIELD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_FIELD ', 'ALL',a.table_name, 'SYS_FIELD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_FIELD ','ALL',a.table_name, 'SYS_FIELD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sys_functionality.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_FUNCTIONALITY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_FUNCTIONALITY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_FUNCTIONALITY ', 'ALL',a.table_name, 'SYS_FUNCTIONALITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_FUNCTIONALITY ','ALL',a.table_name, 'SYS_FUNCTIONALITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_login.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_LOGIN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_LOGIN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_LOGIN ', 'ALL',a.table_name, 'SYS_LOGIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_LOGIN ','ALL',a.table_name, 'SYS_LOGIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sys_message.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_MESSAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_MESSAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_MESSAGE ', 'ALL',a.table_name, 'SYS_MESSAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_MESSAGE ','ALL',a.table_name, 'SYS_MESSAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_message_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_MESSAGE_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_MESSAGE_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_MESSAGE_BCK ', 'ALL',a.table_name, 'SYS_MESSAGE_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_MESSAGE_BCK ','ALL',a.table_name, 'SYS_MESSAGE_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_request.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_REQUEST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_REQUEST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_REQUEST ', 'ALL',a.table_name, 'SYS_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_REQUEST ','ALL',a.table_name, 'SYS_REQUEST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_screen_area.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SCREEN_AREA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SCREEN_AREA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_SCREEN_AREA ', 'ALL',a.table_name, 'SYS_SCREEN_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_SCREEN_AREA ','ALL',a.table_name, 'SYS_SCREEN_AREA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_screen_template.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SCREEN_TEMPLATE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SCREEN_TEMPLATE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_SCREEN_TEMPLATE ', 'ALL',a.table_name, 'SYS_SCREEN_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_SCREEN_TEMPLATE ','ALL',a.table_name, 'SYS_SCREEN_TEMPLATE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_session.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SESSION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SESSION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_SESSION ', 'ALL',a.table_name, 'SYS_SESSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_SESSION ','ALL',a.table_name, 'SYS_SESSION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_shortcut.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SHORTCUT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_SHORTCUT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_SHORTCUT ', 'ALL',a.table_name, 'SYS_SHORTCUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_SHORTCUT ','ALL',a.table_name, 'SYS_SHORTCUT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\system_apparati.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYSTEM_APPARATI','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYSTEM_APPARATI','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYSTEM_APPARATI ', 'ALL',a.table_name, 'SYSTEM_APPARATI') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYSTEM_APPARATI ','ALL',a.table_name, 'SYSTEM_APPARATI') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\system_organ.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYSTEM_ORGAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYSTEM_ORGAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYSTEM_ORGAN ', 'ALL',a.table_name, 'SYSTEM_ORGAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYSTEM_ORGAN ','ALL',a.table_name, 'SYSTEM_ORGAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\sys_time_event_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_TIME_EVENT_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_TIME_EVENT_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_TIME_EVENT_GROUP ', 'ALL',a.table_name, 'SYS_TIME_EVENT_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_TIME_EVENT_GROUP ','ALL',a.table_name, 'SYS_TIME_EVENT_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sys_toolbar.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_TOOLBAR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_TOOLBAR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_TOOLBAR ', 'ALL',a.table_name, 'SYS_TOOLBAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_TOOLBAR ','ALL',a.table_name, 'SYS_TOOLBAR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\sys_vital_sign.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_VITAL_SIGN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','SYS_VITAL_SIGN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SYS_VITAL_SIGN ', 'ALL',a.table_name, 'SYS_VITAL_SIGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SYS_VITAL_SIGN ','ALL',a.table_name, 'SYS_VITAL_SIGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\temp_portaria.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TEMP_PORTARIA','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TEMP_PORTARIA','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TEMP_PORTARIA ', 'ALL',a.table_name, 'TEMP_PORTARIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TEMP_PORTARIA ','ALL',a.table_name, 'TEMP_PORTARIA') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\tests_review.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TESTS_REVIEW','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TESTS_REVIEW','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TESTS_REVIEW ', 'ALL',a.table_name, 'TESTS_REVIEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TESTS_REVIEW ','ALL',a.table_name, 'TESTS_REVIEW') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\time.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TIME','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TIME','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TIME ', 'ALL',a.table_name, 'TIME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TIME ','ALL',a.table_name, 'TIME') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\time_event_group.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_EVENT_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_EVENT_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TIME_EVENT_GROUP ', 'ALL',a.table_name, 'TIME_EVENT_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TIME_EVENT_GROUP ','ALL',a.table_name, 'TIME_EVENT_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\time_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TIME_GROUP ', 'ALL',a.table_name, 'TIME_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TIME_GROUP ','ALL',a.table_name, 'TIME_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\time_group_soft_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_GROUP_SOFT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_GROUP_SOFT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TIME_GROUP_SOFT_INST ', 'ALL',a.table_name, 'TIME_GROUP_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TIME_GROUP_SOFT_INST ','ALL',a.table_name, 'TIME_GROUP_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\time_unit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_UNIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TIME_UNIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TIME_UNIT ', 'ALL',a.table_name, 'TIME_UNIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TIME_UNIT ','ALL',a.table_name, 'TIME_UNIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\toad_plan_sql.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TOAD_PLAN_SQL','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TOAD_PLAN_SQL','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TOAD_PLAN_SQL ', 'ALL',a.table_name, 'TOAD_PLAN_SQL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TOAD_PLAN_SQL ','ALL',a.table_name, 'TOAD_PLAN_SQL') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\toad_plan_table.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TOAD_PLAN_TABLE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TOAD_PLAN_TABLE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TOAD_PLAN_TABLE ', 'ALL',a.table_name, 'TOAD_PLAN_TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TOAD_PLAN_TABLE ','ALL',a.table_name, 'TOAD_PLAN_TABLE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\translation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSLATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSLATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSLATION ', 'ALL',a.table_name, 'TRANSLATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSLATION ','ALL',a.table_name, 'TRANSLATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\translation_bck_20061214.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSLATION_BCK_20061214','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSLATION_BCK_20061214','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSLATION_BCK_20061214 ', 'ALL',a.table_name, 'TRANSLATION_BCK_20061214') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSLATION_BCK_20061214 ','ALL',a.table_name, 'TRANSLATION_BCK_20061214') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\transp_ent_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_ENT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_ENT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSP_ENT_INST ', 'ALL',a.table_name, 'TRANSP_ENT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSP_ENT_INST ','ALL',a.table_name, 'TRANSP_ENT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\transp_entity.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_ENTITY','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_ENTITY','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSP_ENTITY ', 'ALL',a.table_name, 'TRANSP_ENTITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSP_ENTITY ','ALL',a.table_name, 'TRANSP_ENTITY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\transportation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSPORTATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSPORTATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSPORTATION ', 'ALL',a.table_name, 'TRANSPORTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSPORTATION ','ALL',a.table_name, 'TRANSPORTATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\transport_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSPORT_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSPORT_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSPORT_TYPE ', 'ALL',a.table_name, 'TRANSPORT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSPORT_TYPE ','ALL',a.table_name, 'TRANSPORT_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\transp_req.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_REQ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_REQ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSP_REQ ', 'ALL',a.table_name, 'TRANSP_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSP_REQ ','ALL',a.table_name, 'TRANSP_REQ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\transp_req_group.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_REQ_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRANSP_REQ_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRANSP_REQ_GROUP ', 'ALL',a.table_name, 'TRANSP_REQ_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRANSP_REQ_GROUP ','ALL',a.table_name, 'TRANSP_REQ_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\treatment_management.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TREATMENT_MANAGEMENT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TREATMENT_MANAGEMENT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TREATMENT_MANAGEMENT ', 'ALL',a.table_name, 'TREATMENT_MANAGEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TREATMENT_MANAGEMENT ','ALL',a.table_name, 'TREATMENT_MANAGEMENT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE ', 'ALL',a.table_name, 'TRIAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE ','ALL',a.table_name, 'TRIAGE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_board.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_BOARD','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_BOARD','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_BOARD ', 'ALL',a.table_name, 'TRIAGE_BOARD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_BOARD ','ALL',a.table_name, 'TRIAGE_BOARD') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_board_group.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_BOARD_GROUP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_BOARD_GROUP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_BOARD_GROUP ', 'ALL',a.table_name, 'TRIAGE_BOARD_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_BOARD_GROUP ','ALL',a.table_name, 'TRIAGE_BOARD_GROUP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_board_grouping.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_BOARD_GROUPING','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_BOARD_GROUPING','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_BOARD_GROUPING ', 'ALL',a.table_name, 'TRIAGE_BOARD_GROUPING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_BOARD_GROUPING ','ALL',a.table_name, 'TRIAGE_BOARD_GROUPING') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_color.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_COLOR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_COLOR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_COLOR ', 'ALL',a.table_name, 'TRIAGE_COLOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_COLOR ','ALL',a.table_name, 'TRIAGE_COLOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\triage_considerations.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_CONSIDERATIONS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_CONSIDERATIONS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_CONSIDERATIONS ', 'ALL',a.table_name, 'TRIAGE_CONSIDERATIONS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_CONSIDERATIONS ','ALL',a.table_name, 'TRIAGE_CONSIDERATIONS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_disc_help.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISC_HELP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISC_HELP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_DISC_HELP ', 'ALL',a.table_name, 'TRIAGE_DISC_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_DISC_HELP ','ALL',a.table_name, 'TRIAGE_DISC_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\triage_discriminator.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISCRIMINATOR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISCRIMINATOR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_DISCRIMINATOR ', 'ALL',a.table_name, 'TRIAGE_DISCRIMINATOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_DISCRIMINATOR ','ALL',a.table_name, 'TRIAGE_DISCRIMINATOR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_discriminator_help.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISCRIMINATOR_HELP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISCRIMINATOR_HELP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_DISCRIMINATOR_HELP ', 'ALL',a.table_name, 'TRIAGE_DISCRIMINATOR_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_DISCRIMINATOR_HELP ','ALL',a.table_name, 'TRIAGE_DISCRIMINATOR_HELP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\triage_disc_vs_valid.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISC_VS_VALID','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_DISC_VS_VALID','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_DISC_VS_VALID ', 'ALL',a.table_name, 'TRIAGE_DISC_VS_VALID') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_DISC_VS_VALID ','ALL',a.table_name, 'TRIAGE_DISC_VS_VALID') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_n_consid.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_N_CONSID','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_N_CONSID','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_N_CONSID ', 'ALL',a.table_name, 'TRIAGE_N_CONSID') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_N_CONSID ','ALL',a.table_name, 'TRIAGE_N_CONSID') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_nurse.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_NURSE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_NURSE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_NURSE ', 'ALL',a.table_name, 'TRIAGE_NURSE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_NURSE ','ALL',a.table_name, 'TRIAGE_NURSE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_TYPE ', 'ALL',a.table_name, 'TRIAGE_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_TYPE ','ALL',a.table_name, 'TRIAGE_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_units.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_UNITS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_UNITS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_UNITS ', 'ALL',a.table_name, 'TRIAGE_UNITS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_UNITS ','ALL',a.table_name, 'TRIAGE_UNITS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\triage_white_reason.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_WHITE_REASON','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','TRIAGE_WHITE_REASON','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TRIAGE_WHITE_REASON ', 'ALL',a.table_name, 'TRIAGE_WHITE_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TRIAGE_WHITE_REASON ','ALL',a.table_name, 'TRIAGE_WHITE_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\unit_mea_soft_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEA_SOFT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEA_SOFT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('UNIT_MEA_SOFT_INST ', 'ALL',a.table_name, 'UNIT_MEA_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('UNIT_MEA_SOFT_INST ','ALL',a.table_name, 'UNIT_MEA_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\unit_measure.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEASURE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEASURE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('UNIT_MEASURE ', 'ALL',a.table_name, 'UNIT_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('UNIT_MEASURE ','ALL',a.table_name, 'UNIT_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\unit_measure_convert.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEASURE_CONVERT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEASURE_CONVERT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('UNIT_MEASURE_CONVERT ', 'ALL',a.table_name, 'UNIT_MEASURE_CONVERT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('UNIT_MEASURE_CONVERT ','ALL',a.table_name, 'UNIT_MEASURE_CONVERT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\unit_measure_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEASURE_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','UNIT_MEASURE_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('UNIT_MEASURE_TYPE ', 'ALL',a.table_name, 'UNIT_MEASURE_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('UNIT_MEASURE_TYPE ','ALL',a.table_name, 'UNIT_MEASURE_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE ', 'ALL',a.table_name, 'VACCINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE ','ALL',a.table_name, 'VACCINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\vaccine_dep_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_DEP_CLIN_SERV ', 'ALL',a.table_name, 'VACCINE_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_DEP_CLIN_SERV ','ALL',a.table_name, 'VACCINE_DEP_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine_desc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DESC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DESC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_DESC ', 'ALL',a.table_name, 'VACCINE_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_DESC ','ALL',a.table_name, 'VACCINE_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\vaccine_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_DET ', 'ALL',a.table_name, 'VACCINE_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_DET ','ALL',a.table_name, 'VACCINE_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine_dose.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DOSE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DOSE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_DOSE ', 'ALL',a.table_name, 'VACCINE_DOSE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_DOSE ','ALL',a.table_name, 'VACCINE_DOSE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine_dose_admin.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DOSE_ADMIN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_DOSE_ADMIN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_DOSE_ADMIN ', 'ALL',a.table_name, 'VACCINE_DOSE_ADMIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_DOSE_ADMIN ','ALL',a.table_name, 'VACCINE_DOSE_ADMIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine_presc_det.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_PRESC_DET','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_PRESC_DET','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_PRESC_DET ', 'ALL',a.table_name, 'VACCINE_PRESC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_PRESC_DET ','ALL',a.table_name, 'VACCINE_PRESC_DET') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine_presc_plan.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_PRESC_PLAN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_PRESC_PLAN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_PRESC_PLAN ', 'ALL',a.table_name, 'VACCINE_PRESC_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_PRESC_PLAN ','ALL',a.table_name, 'VACCINE_PRESC_PLAN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine_prescription.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_PRESCRIPTION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_PRESCRIPTION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_PRESCRIPTION ', 'ALL',a.table_name, 'VACCINE_PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_PRESCRIPTION ','ALL',a.table_name, 'VACCINE_PRESCRIPTION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vaccine_status.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_STATUS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VACCINE_STATUS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VACCINE_STATUS ', 'ALL',a.table_name, 'VACCINE_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VACCINE_STATUS ','ALL',a.table_name, 'VACCINE_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vbz$object_stats.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VBZ$OBJECT_STATS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VBZ$OBJECT_STATS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VBZ$OBJECT_STATS ', 'ALL',a.table_name, 'VBZ$OBJECT_STATS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VBZ$OBJECT_STATS ','ALL',a.table_name, 'VBZ$OBJECT_STATS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\viewer.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VIEWER ', 'ALL',a.table_name, 'VIEWER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VIEWER ','ALL',a.table_name, 'VIEWER') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\viewer_refresh.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER_REFRESH','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER_REFRESH','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VIEWER_REFRESH ', 'ALL',a.table_name, 'VIEWER_REFRESH') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VIEWER_REFRESH ','ALL',a.table_name, 'VIEWER_REFRESH') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\viewer_synch_param.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER_SYNCH_PARAM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER_SYNCH_PARAM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VIEWER_SYNCH_PARAM ', 'ALL',a.table_name, 'VIEWER_SYNCH_PARAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VIEWER_SYNCH_PARAM ','ALL',a.table_name, 'VIEWER_SYNCH_PARAM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\viewer_synchronize.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER_SYNCHRONIZE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VIEWER_SYNCHRONIZE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VIEWER_SYNCHRONIZE ', 'ALL',a.table_name, 'VIEWER_SYNCHRONIZE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VIEWER_SYNCHRONIZE ','ALL',a.table_name, 'VIEWER_SYNCHRONIZE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\visit.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VISIT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VISIT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VISIT ', 'ALL',a.table_name, 'VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VISIT ','ALL',a.table_name, 'VISIT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\vital_sign.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VITAL_SIGN ', 'ALL',a.table_name, 'VITAL_SIGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VITAL_SIGN ','ALL',a.table_name, 'VITAL_SIGN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vital_sign_desc.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_DESC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_DESC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VITAL_SIGN_DESC ', 'ALL',a.table_name, 'VITAL_SIGN_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VITAL_SIGN_DESC ','ALL',a.table_name, 'VITAL_SIGN_DESC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vital_sign_notes.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_NOTES','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_NOTES','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VITAL_SIGN_NOTES ', 'ALL',a.table_name, 'VITAL_SIGN_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VITAL_SIGN_NOTES ','ALL',a.table_name, 'VITAL_SIGN_NOTES') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vital_sign_read.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_READ','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_READ','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VITAL_SIGN_READ ', 'ALL',a.table_name, 'VITAL_SIGN_READ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VITAL_SIGN_READ ','ALL',a.table_name, 'VITAL_SIGN_READ') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vital_sign_read_error.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_READ_ERROR','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_READ_ERROR','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VITAL_SIGN_READ_ERROR ', 'ALL',a.table_name, 'VITAL_SIGN_READ_ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VITAL_SIGN_READ_ERROR ','ALL',a.table_name, 'VITAL_SIGN_READ_ERROR') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vital_sign_relation.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_RELATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_RELATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VITAL_SIGN_RELATION ', 'ALL',a.table_name, 'VITAL_SIGN_RELATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VITAL_SIGN_RELATION ','ALL',a.table_name, 'VITAL_SIGN_RELATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vital_sign_unit_measure.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_UNIT_MEASURE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VITAL_SIGN_UNIT_MEASURE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VITAL_SIGN_UNIT_MEASURE ', 'ALL',a.table_name, 'VITAL_SIGN_UNIT_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VITAL_SIGN_UNIT_MEASURE ','ALL',a.table_name, 'VITAL_SIGN_UNIT_MEASURE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vs_clin_serv.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VS_CLIN_SERV','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VS_CLIN_SERV','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VS_CLIN_SERV ', 'ALL',a.table_name, 'VS_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VS_CLIN_SERV ','ALL',a.table_name, 'VS_CLIN_SERV') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\vs_soft_inst.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','VS_SOFT_INST','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','VS_SOFT_INST','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('VS_SOFT_INST ', 'ALL',a.table_name, 'VS_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('VS_SOFT_INST ','ALL',a.table_name, 'VS_SOFT_INST') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\white_reason.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WHITE_REASON','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WHITE_REASON','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WHITE_REASON ', 'ALL',a.table_name, 'WHITE_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WHITE_REASON ','ALL',a.table_name, 'WHITE_REASON') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_call_queue.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_CALL_QUEUE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_CALL_QUEUE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_CALL_QUEUE ', 'ALL',a.table_name, 'WL_CALL_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_CALL_QUEUE ','ALL',a.table_name, 'WL_CALL_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\wl_demo.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_DEMO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_DEMO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_DEMO ', 'ALL',a.table_name, 'WL_DEMO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_DEMO ','ALL',a.table_name, 'WL_DEMO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_demo_bck.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_DEMO_BCK','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_DEMO_BCK','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_DEMO_BCK ', 'ALL',a.table_name, 'WL_DEMO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_DEMO_BCK ','ALL',a.table_name, 'WL_DEMO_BCK') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\wl_machine.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_MACHINE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_MACHINE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_MACHINE ', 'ALL',a.table_name, 'WL_MACHINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_MACHINE ','ALL',a.table_name, 'WL_MACHINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_mach_prof_queue.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_MACH_PROF_QUEUE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_MACH_PROF_QUEUE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_MACH_PROF_QUEUE ', 'ALL',a.table_name, 'WL_MACH_PROF_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_MACH_PROF_QUEUE ','ALL',a.table_name, 'WL_MACH_PROF_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_msg_queue.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_MSG_QUEUE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_MSG_QUEUE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_MSG_QUEUE ', 'ALL',a.table_name, 'WL_MSG_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_MSG_QUEUE ','ALL',a.table_name, 'WL_MSG_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_patient_sonho.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PATIENT_SONHO','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PATIENT_SONHO','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_PATIENT_SONHO ', 'ALL',a.table_name, 'WL_PATIENT_SONHO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_PATIENT_SONHO ','ALL',a.table_name, 'WL_PATIENT_SONHO') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_patient_sonho_imp.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PATIENT_SONHO_IMP','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PATIENT_SONHO_IMP','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_PATIENT_SONHO_IMP ', 'ALL',a.table_name, 'WL_PATIENT_SONHO_IMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_PATIENT_SONHO_IMP ','ALL',a.table_name, 'WL_PATIENT_SONHO_IMP') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_patient_sonho_transfered.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PATIENT_SONHO_TRANSFERED','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PATIENT_SONHO_TRANSFERED','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_PATIENT_SONHO_TRANSFERED ', 'ALL',a.table_name, 'WL_PATIENT_SONHO_TRANSFERED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_PATIENT_SONHO_TRANSFERED ','ALL',a.table_name, 'WL_PATIENT_SONHO_TRANSFERED') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_prof_room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PROF_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_PROF_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_PROF_ROOM ', 'ALL',a.table_name, 'WL_PROF_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_PROF_ROOM ','ALL',a.table_name, 'WL_PROF_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_queue.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_QUEUE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_QUEUE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_QUEUE ', 'ALL',a.table_name, 'WL_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_QUEUE ','ALL',a.table_name, 'WL_QUEUE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_status.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_STATUS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_STATUS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_STATUS ', 'ALL',a.table_name, 'WL_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_STATUS ','ALL',a.table_name, 'WL_STATUS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\wl_topics.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_TOPICS','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_TOPICS','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_TOPICS ', 'ALL',a.table_name, 'WL_TOPICS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_TOPICS ','ALL',a.table_name, 'WL_TOPICS') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_waiting_line.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_WAITING_LINE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_WAITING_LINE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_WAITING_LINE ', 'ALL',a.table_name, 'WL_WAITING_LINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_WAITING_LINE ','ALL',a.table_name, 'WL_WAITING_LINE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\wl_waiting_line_0104.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_WAITING_LINE_0104','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_WAITING_LINE_0104','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_WAITING_LINE_0104 ', 'ALL',a.table_name, 'WL_WAITING_LINE_0104') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_WAITING_LINE_0104 ','ALL',a.table_name, 'WL_WAITING_LINE_0104') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wl_waiting_room.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WL_WAITING_ROOM','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WL_WAITING_ROOM','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WL_WAITING_ROOM ', 'ALL',a.table_name, 'WL_WAITING_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WL_WAITING_ROOM ','ALL',a.table_name, 'WL_WAITING_ROOM') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\wound_charac.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_CHARAC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_CHARAC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WOUND_CHARAC ', 'ALL',a.table_name, 'WOUND_CHARAC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WOUND_CHARAC ','ALL',a.table_name, 'WOUND_CHARAC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wound_eval_charac.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_EVAL_CHARAC','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_EVAL_CHARAC','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WOUND_EVAL_CHARAC ', 'ALL',a.table_name, 'WOUND_EVAL_CHARAC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WOUND_EVAL_CHARAC ','ALL',a.table_name, 'WOUND_EVAL_CHARAC') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wound_evaluation.tab'

select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_EVALUATION','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_EVALUATION','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WOUND_EVALUATION ', 'ALL',a.table_name, 'WOUND_EVALUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WOUND_EVALUATION ','ALL',a.table_name, 'WOUND_EVALUATION') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wound_treat.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_TREAT','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_TREAT','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WOUND_TREAT ', 'ALL',a.table_name, 'WOUND_TREAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WOUND_TREAT ','ALL',a.table_name, 'WOUND_TREAT') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\wound_type.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_TYPE','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','WOUND_TYPE','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;

SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('WOUND_TYPE ', 'ALL',a.table_name, 'WOUND_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('WOUND_TYPE ','ALL',a.table_name, 'WOUND_TYPE') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dr$d_idx$r.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$R','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$R','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$D_IDX$R ', 'ALL',a.table_name, 'DR$D_IDX$R') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$D_IDX$R ','ALL',a.table_name, 'DR$D_IDX$R') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dr$d_idx$n.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$N','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$N','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$D_IDX$N ', 'ALL',a.table_name, 'DR$D_IDX$N') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$D_IDX$N ','ALL',a.table_name, 'DR$D_IDX$N') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dr$d_idx$k.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$K','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$K','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$D_IDX$K ', 'ALL',a.table_name, 'DR$D_IDX$K') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$D_IDX$K ','ALL',a.table_name, 'DR$D_IDX$K') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dr$d_idx$i.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$I','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$D_IDX$I','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$D_IDX$I ', 'ALL',a.table_name, 'DR$D_IDX$I') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$D_IDX$I ','ALL',a.table_name, 'DR$D_IDX$I') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;

spool off

spool 'c:\mighdc\alert\tables\dr$snomed_idx$i.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$I','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$I','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$SNOMED_IDX$I ', 'ALL',a.table_name, 'DR$SNOMED_IDX$I') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$SNOMED_IDX$I ','ALL',a.table_name, 'DR$SNOMED_IDX$I') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dr$snomed_idx$k.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$K','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$K','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$SNOMED_IDX$K ', 'ALL',a.table_name, 'DR$SNOMED_IDX$K') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$SNOMED_IDX$K ','ALL',a.table_name, 'DR$SNOMED_IDX$K') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\dr$snomed_idx$r.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$R','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$R','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$SNOMED_IDX$R ', 'ALL',a.table_name, 'DR$SNOMED_IDX$R') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$SNOMED_IDX$R ','ALL',a.table_name, 'DR$SNOMED_IDX$R') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\dr$snomed_idx$n.tab'
select substr(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$N','ALERT'),'"',''),'ALERT.',''),0,INSTR(replace(replace(dbms_metadata.get_ddl('TABLE','DR$SNOMED_IDX$N','ALERT'),'"',''),'ALERT.','' ),') PCTFREE')) || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('DR$SNOMED_IDX$N ', 'ALL',a.table_name, 'DR$SNOMED_IDX$N') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('DR$SNOMED_IDX$N ','ALL',a.table_name, 'DR$SNOMED_IDX$N') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool 'c:\mighdc\alert\tables\quest_sl_temp_explain1.tab'
select replace(replace(dbms_metadata.get_ddl('TABLE','QUEST_SL_TEMP_EXPLAIN1','ALERT'),'"',''),'QUEST_SL_TEMP_EXPLAIN1.','') || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('QUEST_SL_TEMP_EXPLAIN1 ', 'ALL',a.table_name, 'QUEST_SL_TEMP_EXPLAIN1') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('QUEST_SL_TEMP_EXPLAIN1 ','ALL',a.table_name, 'QUEST_SL_TEMP_EXPLAIN1') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\quest_temp_explain.tab'
select replace(replace(dbms_metadata.get_ddl('TABLE','QUEST_TEMP_EXPLAIN','ALERT'),'"',''),'QUEST_TEMP_EXPLAIN.','') || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('QUEST_TEMP_EXPLAIN ', 'ALL',a.table_name, 'QUEST_TEMP_EXPLAIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('QUEST_TEMP_EXPLAIN ','ALL',a.table_name, 'QUEST_TEMP_EXPLAIN') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\sch_mult_reschedule_aux.tab'

select replace(replace(dbms_metadata.get_ddl('TABLE','SCH_MULT_RESCHEDULE_AUX','ALERT'),'"',''),'SCH_MULT_RESCHEDULE_AUX.','') || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('SCH_MULT_RESCHEDULE_AUX ', 'ALL',a.table_name, 'SCH_MULT_RESCHEDULE_AUX') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('SCH_MULT_RESCHEDULE_AUX ','ALL',a.table_name, 'SCH_MULT_RESCHEDULE_AUX') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off

spool 'c:\mighdc\alert\tables\tmp_nurse_summary.tab'
select replace(replace(dbms_metadata.get_ddl('TABLE','TMP_NURSE_SUMMARY','ALERT'),'"',''),'TMP_NURSE_SUMMARY.','') || ';' text from dual;
SELECT 'COMMENT ON TABLE ' || Lower(a.table_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_tab_comments a  WHERE  a.table_name = Decode('TMP_NURSE_SUMMARY ', 'ALL',a.table_name, 'TMP_NURSE_SUMMARY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
SELECT 'COMMENT ON COLUMN ' || Lower(a.table_name || '.' || a.column_name) || ' IS ''' || replace(a.comments,'''','''''') || ''' ;' text FROM   all_col_comments a WHERE  a.table_name = Decode('TMP_NURSE_SUMMARY ','ALL',a.table_name, 'TMP_NURSE_SUMMARY') AND a.owner = Upper('ALERT') AND a.comments  IS NOT NULL;
spool off


spool c:\mighdc\alert\tables\execute_tables.sql
select 'set sqlbl on;' from dual;
select '@@' || lower(table_name) || '.tab' from all_tables where owner = 'ALERT';
spool off

