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
      --ALERT.ALERT_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.ALERT_DIAGNOSIS DROP CONSTRAINT ADI_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.ALERT_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.ALERT_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.ALERT_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.ALERT_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.DIAG_DIAG_CONDITION
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAG_DIAG_CONDITION DROP CONSTRAINT DCN_DII_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAG_DIAG_CONDITION MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAG_DIAG_CONDITION ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.DIAG_DIAG_CONDITION.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAG_DIAG_CONDITION ADD CONSTRAINT DCN_DII_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Constraint already created.');
      END;
      --ALERT.DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS DROP CONSTRAINT DIAG_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.DIAGNOSIS_CAT
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_CAT DROP CONSTRAINT DCAT_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_CAT MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_CAT ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.DIAGNOSIS_CAT.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_CAT ADD CONSTRAINT DCAT_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_CAT - Constraint already created.');
      END;
      --ALERT.DIAGNOSIS_DEP_CLIN_SERV
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_DEP_CLIN_SERV DROP CONSTRAINT DSC_DIAG_FK';
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
      --ALERT.DIAGNOSIS_MARKET
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_MARKET DROP CONSTRAINT DIAG_MRK_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_MARKET MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_MARKET ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.DIAGNOSIS_MARKET.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DIAGNOSIS_MARKET ADD CONSTRAINT DIAG_MRK_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DIAGNOSIS_MARKET - Constraint already created.');
      END;
      --ALERT.DISCHARGE_DETAIL
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DISCHARGE_DETAIL DROP CONSTRAINT DD_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DISCHARGE_DETAIL MODIFY ID_TRANSFER_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DISCHARGE_DETAIL ADD ID_DIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.DISCHARGE_DETAIL.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.DISCHARGE_DETAIL SET ID_DIAG_INST_OWNER = 0 WHERE ID_TRANSFER_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DISCHARGE_DETAIL ADD CONSTRAINT DD_DIAG_FK FOREIGN KEY(ID_TRANSFER_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DISCHARGE_DETAIL - Constraint already created.');
      END;
      --ALERT.DOC_TEMPLATE_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DOC_TEMPLATE_DIAGNOSIS DROP CONSTRAINT DOCTD_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DOC_TEMPLATE_DIAGNOSIS MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DOC_TEMPLATE_DIAGNOSIS ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.DOC_TEMPLATE_DIAGNOSIS.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.DOC_TEMPLATE_DIAGNOSIS ADD CONSTRAINT DOCTD_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.DOC_TEMPLATE_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.EPIS_ANAMNESIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_ANAMNESIS DROP CONSTRAINT COMP_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_ANAMNESIS ADD ID_DIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.EPIS_ANAMNESIS.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.EPIS_ANAMNESIS SET ID_DIAG_INST_OWNER = 0 WHERE ID_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_ANAMNESIS ADD CONSTRAINT COMP_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.EPIS_ANAMNESIS - Constraint already created.');
      END;
      --ALERT.EPIS_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS DROP CONSTRAINT EDS_DIAG_FK';
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
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS MODIFY ID_DIAGNOSIS NUMBER(24)';
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
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
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
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.EPIS_DIAGNOSIS.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.EPIS_DIAGNOSIS - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.EPIS_DIAGNOSIS ADD CONSTRAINT EDS_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
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
      --ALERT.MCDT_REQ_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.MCDT_REQ_DIAGNOSIS DROP CONSTRAINT MRD_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.MCDT_REQ_DIAGNOSIS ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.MCDT_REQ_DIAGNOSIS.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.MCDT_REQ_DIAGNOSIS ADD CONSTRAINT MRD_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.MCDT_REQ_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.NURSE_TEA_DET_DIAG
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.NURSE_TEA_DET_DIAG DROP CONSTRAINT NTG_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.NURSE_TEA_DET_DIAG ADD ID_DIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.NURSE_TEA_DET_DIAG.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.NURSE_TEA_DET_DIAG SET ID_DIAG_INST_OWNER = 0 WHERE ID_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.NURSE_TEA_DET_DIAG ADD CONSTRAINT NTG_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.NURSE_TEA_DET_DIAG - Constraint already created.');
      END;
      --ALERT.OPINION_REASON
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.OPINION_REASON DROP CONSTRAINT OPR_DIAGNOSIS_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.OPINION_REASON ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.OPINION_REASON.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.OPINION_REASON ADD CONSTRAINT OPR_DIAGNOSIS_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.OPINION_REASON - Constraint already created.');
      END;
      --ALERT.P1_EXR_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.P1_EXR_DIAGNOSIS DROP CONSTRAINT PEI_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.P1_EXR_DIAGNOSIS MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.P1_EXR_DIAGNOSIS ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.P1_EXR_DIAGNOSIS.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.P1_EXR_DIAGNOSIS ADD CONSTRAINT PEI_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.P1_EXR_DIAGNOSIS - Constraint already created.');
      END;
      --ALERT.PAT_FAMILY_DISEASE
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_FAMILY_DISEASE DROP CONSTRAINT PTFDI_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_FAMILY_DISEASE MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_FAMILY_DISEASE ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_FAMILY_DISEASE.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_FAMILY_DISEASE ADD CONSTRAINT PTFDI_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_FAMILY_DISEASE - Constraint already created.');
      END;
      --ALERT.PAT_HISTORY
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY DROP CONSTRAINT PHY_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_HISTORY.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY ADD CONSTRAINT PHY_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_HISTORY - Constraint already created.');
      END;
      --ALERT.PAT_HISTORY_DIAGNOSIS
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS DROP CONSTRAINT PHD_DIAG_FK';
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
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS MODIFY ID_DIAGNOSIS NUMBER(24)';
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
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS ADD ID_DIAG_INST_OWNER NUMBER(24)';
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
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_HISTORY_DIAGNOSIS.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.PAT_HISTORY_DIAGNOSIS SET ID_DIAG_INST_OWNER = 0 WHERE ID_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.DIAG_DIAG_CONDITION - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_HISTORY_DIAGNOSIS ADD CONSTRAINT PHD_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
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
      --ALERT.PAT_MED_DECL
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_MED_DECL DROP CONSTRAINT PMD_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_MED_DECL MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_MED_DECL ADD ID_DIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_MED_DECL.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.PAT_MED_DECL SET ID_DIAG_INST_OWNER = 0 WHERE ID_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_MED_DECL ADD CONSTRAINT PMD_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PAT_MED_DECL - Constraint already created.');
      END;
      --ALERT.PAT_PROBLEM
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM DROP CONSTRAINT PPM_DIAG_FK';
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
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM MODIFY ID_DIAGNOSIS NUMBER(24)';
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
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM ADD ID_DIAG_INST_OWNER NUMBER(24)';
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
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PAT_PROBLEM.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.PAT_PROBLEM SET ID_DIAG_INST_OWNER = 0 WHERE ID_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PAT_PROBLEM - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PAT_PROBLEM ADD CONSTRAINT PPM_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
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
      --ALERT.PROGRESS_NOTES
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROGRESS_NOTES DROP CONSTRAINT PNS_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROGRESS_NOTES MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROGRESS_NOTES ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PROGRESS_NOTES.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROGRESS_NOTES ADD CONSTRAINT PNS_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROGRESS_NOTES - Constraint already created.');
      END;
      --ALERT.PROTOC_DIAG
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROTOC_DIAG DROP CONSTRAINT PDIG_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROTOC_DIAG MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROTOC_DIAG ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.PROTOC_DIAG.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.PROTOC_DIAG ADD CONSTRAINT PDIG_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.PROTOC_DIAG - Constraint already created.');
      END;
      --ALERT.SAMPLE_TEXT
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SAMPLE_TEXT DROP CONSTRAINT SSTT_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SAMPLE_TEXT ADD ID_DIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.SAMPLE_TEXT.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.SAMPLE_TEXT SET ID_DIAG_INST_OWNER = 0 WHERE ID_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SAMPLE_TEXT ADD CONSTRAINT SSTT_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SAMPLE_TEXT - Constraint already created.');
      END;
      --ALERT.SCHEDULE_SR
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SCHEDULE_SR DROP CONSTRAINT SCHED_SR_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SCHEDULE_SR MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SCHEDULE_SR ADD ID_DIAG_INST_OWNER NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.SCHEDULE_SR.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'UPDATE ALERT.SCHEDULE_SR SET ID_DIAG_INST_OWNER = 0 WHERE ID_DIAGNOSIS IS NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SCHEDULE_SR ADD CONSTRAINT SCHED_SR_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SCHEDULE_SR - Constraint already created.');
      END;
      --ALERT.SR_BASE_DIAG
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SR_BASE_DIAG DROP CONSTRAINT SBG_DIAG_FK';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SR_BASE_DIAG MODIFY ID_DIAGNOSIS NUMBER(24)';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SR_BASE_DIAG ADD ID_DIAG_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already created.');
      END;
      BEGIN
         EXECUTE IMMEDIATE 'COMMENT ON COLUMN ALERT.SR_BASE_DIAG.ID_DIAG_INST_OWNER IS ''Institution owner of the concept. Default 0 - ALERT''';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Table does not exist.');
      END;      
      BEGIN
         EXECUTE IMMEDIATE 'ALTER TABLE ALERT.SR_BASE_DIAG ADD CONSTRAINT SBG_DIAG_FK FOREIGN KEY(ID_DIAGNOSIS, ID_DIAG_INST_OWNER) REFERENCES ALERT_CORE_DATA.CONCEPT_VERSION(ID_CONCEPT_VERSION, ID_INST_OWNER) NOVALIDATE';
      EXCEPTION
      WHEN e_table_dont_exist THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Table does not exist.');
      WHEN e_already_dropped THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already dropped.');
      WHEN e_col_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Column already created.');
      WHEN e_cnt_already_exists THEN
         dbms_output.put_line('ALERT.SR_BASE_DIAG - Constraint already created.');
      END;
END;
/
