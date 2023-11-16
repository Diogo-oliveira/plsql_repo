set feedback off
set termout off
set echo off
set heading off
set verify off
set pau off
set long 10000
set trims on
set lines 1000
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'TABLESPACE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'CONSTRAINTS_AS_ALTER', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', true)
col text format A1000 word wrap

spool 'c:\mighdc\alert\tablespaces\index_l.sql'
select 'alter table ' || table_name || ' move tablespace INDEX_L;' text from all_tables where owner = 'ALERT' and lower(tablespace_name) = 'index_l';
select 'alter index ' || index_name || ' rebuild tablespace INDEX_L;' text from all_indexes where owner = 'ALERT' and lower(tablespace_name) = 'index_l';
spool off

spool 'c:\mighdc\alert\tablespaces\index_m.sql'
select 'alter table ' || table_name || ' move tablespace INDEX_M;' text from all_tables where owner = 'ALERT' and lower(tablespace_name) = 'index_m';
select 'alter index ' || index_name || ' rebuild tablespace INDEX_M;' text from all_indexes where owner = 'ALERT' and lower(tablespace_name) = 'index_m';
spool off

spool 'c:\mighdc\alert\tablespaces\index_s.sql'
select 'alter table ' || table_name || ' move tablespace INDEX_S;' text from all_tables where owner = 'ALERT' and lower(tablespace_name) = 'index_s';
select 'alter index ' || index_name || ' rebuild tablespace INDEX_S;' text from all_indexes where owner = 'ALERT' and lower(tablespace_name) = 'index_s';

spool off

spool 'c:\mighdc\alert\tablespaces\table_l.sql'
select 'alter table ' || table_name || ' move tablespace TABLE_L;' text from all_tables where owner = 'ALERT' and lower(tablespace_name) = 'table_l';
select 'alter index ' || index_name || ' rebuild tablespace TABLE_L;' text from all_indexes where owner = 'ALERT' and lower(tablespace_name) = 'table_l';
spool off

spool 'c:\mighdc\alert\tablespaces\table_m.sql'
select 'alter table ' || table_name || ' move tablespace TABLE_M;' text from all_tables where owner = 'ALERT' and lower(tablespace_name) = 'table_m';
select 'alter index ' || index_name || ' rebuild tablespace TABLE_M;' text from all_indexes where owner = 'ALERT' and lower(tablespace_name) = 'table_m';
spool off

spool 'c:\mighdc\alert\tablespaces\table_s.sql'

select 'alter table ' || table_name || ' move tablespace TABLE_S;' text from all_tables where owner = 'ALERT' and lower(tablespace_name) = 'table_s';
select 'alter index ' || index_name || ' rebuild tablespace TABLE_S;' text from all_indexes where owner = 'ALERT' and lower(tablespace_name) = 'table_s';
spool off

spool 'c:\mighdc\alert\tablespaces\table_xl.sql'
select 'alter table ' || table_name || ' move tablespace TABLE_XL;' text from all_tables where owner = 'ALERT' and lower(tablespace_name) = 'table_xl';
select 'alter index ' || index_name || ' rebuild tablespace TABLE_XL;' text from all_indexes where owner = 'ALERT' and lower(tablespace_name) = 'table_xl';
spool off


spool 'c:\mighdc\alert\tablespaces\execute_tablespaces.sql'
select '@@' || lower(tablespace_name) || '.sql' from dba_tablespaces where tablespace_name like 'TABLE%' OR tablespace_name like 'INDEX%';
spool off



-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 30/11/2010 13:46
-- CHANGE REASON: [ALERT-145880 ] Botão para efectivar pacientes
alter index WWL_PRFLG_IDX rebuild tablespace INDEX_L;
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2011-02-25
-- CHANGE REASON: ALERT-163535

alter index ERDH_EXAM_FK_I rebuild tablespace INDEX_M;
alter index ERDH_EREQ_FK_I rebuild tablespace INDEX_M;
alter index ERDH_ERD_FK_I rebuild tablespace INDEX_M;

-- CHANGE END: Bruno Martins

-- CHANGED BY: Ruben Araujo
-- CHANGE DATE: 29/04/2016 11:02
-- CHANGE REASON: [ ALERT-320778] Move indexes table space: ALERT_DATA to ALERT_IDX

begin
pk_versioning.run('ALTER INDEX ALERT.CS_EPIS_ACT_UK REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT.DGCFG_PK REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT.DIAG_EA_PK REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT.IPD_CSC_FK_IDX REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT.IPD_CSO_FK_IDX REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT.PK_RIL REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT.PK_RLID REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT.RREP_PK REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
pk_versioning.run('ALTER INDEX ALERT_APSSCHDLR_TR.REQ_BK REBUILD TABLESPACE ALERT_IDX');
END;
/

begin
ALTER TABLE ALERT.EPIS_DIAG_NOTES_HIST MOVE LOB (NOTES) STORE AS (TABLESPACE ALERT_LOB );
END;
/

-- CHANGE END: Ruben Araujo
