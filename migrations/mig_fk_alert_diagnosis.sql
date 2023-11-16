DECLARE
   e_table_dont_exist EXCEPTION;
   e_already_dropped EXCEPTION;
   e_col_already_exists EXCEPTION;
   e_cnt_already_exists EXCEPTION;

   PRAGMA EXCEPTION_INIT(e_table_dont_exist, -942);
   PRAGMA EXCEPTION_INIT(e_already_dropped, -2443);
   PRAGMA EXCEPTION_INIT(e_col_already_exists, -1430);
   PRAGMA EXCEPTION_INIT(e_cnt_already_exists, -2275);
BEGIN
      --ALERT.CLIN_SERV_ALERT_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.CLIN_SERV_ALERT_DIAGNOSIS DROP CONSTRAINT CSAD_ADI_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.CLIN_SERV_ALERT_DIAGNOSIS MODIFY ID_ALERT_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.CLIN_SERV_ALERT_DIAGNOSIS ADD ID_ADIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.CLIN_SERV_ALERT_DIAGNOSIS.ID_ADIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.CLIN_SERV_ALERT_DIAGNOSIS ADD CONSTRAINT CSAD_ADI_FK FOREIGN KEY(ID_ALERT_DIAGNOSIS, ID_ADIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_TERM(ID_CONCEPT_TERM, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.CLIN_SERV_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.COMPLAINT_ALERT_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.COMPLAINT_ALERT_DIAGNOSIS DROP CONSTRAINT CAI_ADI_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.COMPLAINT_ALERT_DIAGNOSIS MODIFY ID_ALERT_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.COMPLAINT_ALERT_DIAGNOSIS ADD ID_ADIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.COMPLAINT_ALERT_DIAGNOSIS.ID_ADIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.COMPLAINT_ALERT_DIAGNOSIS ADD CONSTRAINT CAI_ADI_FK FOREIGN KEY(ID_ALERT_DIAGNOSIS, ID_ADIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_TERM(ID_CONCEPT_TERM, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.COMPLAINT_ALERT_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.DIAGNOSIS_DEP_CLIN_SERV
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_DEP_CLIN_SERV DROP CONSTRAINT DSC_ADI_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_DEP_CLIN_SERV - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_DEP_CLIN_SERV - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_DEP_CLIN_SERV - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_DEP_CLIN_SERV - Constraint already created.');
      END;
      --ALERT.EPIS_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS DROP CONSTRAINT EDS_ADI_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS MODIFY ID_ALERT_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS ADD ID_ADIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.EPIS_DIAGNOSIS.ID_ADIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.EPIS_DIAGNOSIS SET ID_ADIAG_INST_OWNER = 0 WHERE ID_ALERT_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS ADD CONSTRAINT EDS_ADI_FK FOREIGN KEY(ID_ALERT_DIAGNOSIS, ID_ADIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_TERM(ID_CONCEPT_TERM, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.PAT_HISTORY_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS DROP CONSTRAINT PHD_ADIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS MODIFY ID_ALERT_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS ADD ID_ADIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_HISTORY_DIAGNOSIS.ID_ADIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.PAT_HISTORY_DIAGNOSIS SET ID_ADIAG_INST_OWNER = 0 WHERE ID_ALERT_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS ADD CONSTRAINT PHD_ADIAG_FK FOREIGN KEY(ID_ALERT_DIAGNOSIS, ID_ADIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_TERM(ID_CONCEPT_TERM, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.PAT_PREGNANCY_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PREGNANCY_DIAGNOSIS DROP CONSTRAINT PPYD_ADI_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PREGNANCY_DIAGNOSIS ADD ID_ADIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_PREGNANCY_DIAGNOSIS.ID_ADIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PREGNANCY_DIAGNOSIS ADD CONSTRAINT PPYD_ADI_FK FOREIGN KEY(ID_ALERT_DIAGNOSIS, ID_ADIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_TERM(ID_CONCEPT_TERM, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST DROP CONSTRAINT PYDH_ADI_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST ADD ID_ADIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST.ID_ADIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST ADD CONSTRAINT PYDH_ADI_FK FOREIGN KEY(ID_ALERT_DIAGNOSIS, ID_ADIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_TERM(ID_CONCEPT_TERM, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PREGNANCY_DIAGNOSIS_HIST - Constraint already created.');
      END;
      --ALERT.PAT_PROBLEM
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM DROP CONSTRAINT PPM_ADI_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM MODIFY ID_ALERT_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM ADD ID_ADIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_PROBLEM.ID_ADIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.PAT_PROBLEM SET ID_ADIAG_INST_OWNER = 0 WHERE ID_ALERT_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM ADD CONSTRAINT PPM_ADI_FK FOREIGN KEY(ID_ALERT_DIAGNOSIS, ID_ADIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_TERM(ID_CONCEPT_TERM, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Constraint already created.');
      END;
END;
/
