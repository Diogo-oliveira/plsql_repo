DECLARE
    PROCEDURE handle_error
    (
        i_call_obj_name IN VARCHAR2,
        i_script        IN VARCHAR2
    ) IS
    BEGIN
        dbms_output.put_line(i_call_obj_name || ' (' || i_script || ') - ' || SQLERRM);
    END handle_error;

    PROCEDURE run_script
    (
        i_call_obj_name IN VARCHAR2,
        i_script        IN VARCHAR2
    ) IS
    BEGIN
        EXECUTE IMMEDIATE i_script;
    EXCEPTION
        WHEN OTHERS THEN
            handle_error(i_call_obj_name => i_call_obj_name, i_script => i_script);
    END run_script;

    PROCEDURE clean_invalid_records IS
    BEGIN
        DELETE FROM epis_diag_stag_pfact;
    
        DELETE FROM epis_dstag_pfact_hist;
    
        DELETE FROM epis_diag_stag e
         WHERE e.id_staging_basis IS NULL;
    
        DELETE FROM epis_diag_stag_hist e
         WHERE e.id_staging_basis IS NULL;
    END clean_invalid_records;

    PROCEDURE set_diag_stag_col_not_null IS
        l_proc_name CONSTANT VARCHAR2(50 CHAR) := 'SET_DIAG_STAG_COL_NOT_NULL';
    BEGIN
        --EPIS_DIAG_STAG
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG MODIFY ID_STAGING_BASIS NOT NULL');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG MODIFY ID_SBASIS_INST_OWNER DEFAULT 0 NOT NULL');
        --EPIS_DIAG_STAG_HIST
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_HIST MODIFY ID_STAGING_BASIS NOT NULL');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_HIST MODIFY ID_SBASIS_INST_OWNER DEFAULT 0 NOT NULL');
    END set_diag_stag_col_not_null;

    -->epis_diag_stag|constraint
    PROCEDURE set_diag_stag_col_pk IS
        l_proc_name CONSTANT VARCHAR2(50 CHAR) := 'SET_DIAG_STAG_COL_PK';
    BEGIN
        --EPIS_DIAG_STAG_PFACT
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_PFACT DROP CONSTRAINT EDSPF_EDSTGG_FK');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_PFACT DROP CONSTRAINT EDSPF_PK');
        --EPIS_DIAG_STAG
        run_script(i_call_obj_name => l_proc_name, i_script => 'ALTER TABLE EPIS_DIAG_STAG DROP CONSTRAINT EDSTGG_PK');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG ADD CONSTRAINT EDSTGG_PK PRIMARY KEY (ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS) USING INDEX TABLESPACE ALERT_IDX');
        --EPIS_DSTAG_PFACT_HIST
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DSTAG_PFACT_HIST DROP CONSTRAINT EDSPFH_EDSTGGH_FK');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DSTAG_PFACT_HIST DROP CONSTRAINT EDSPFH_PK');
        --EPIS_DIAG_STAG_HIST
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_HIST DROP CONSTRAINT EDSTGGH_PK');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_HIST ADD CONSTRAINT EDSTGGH_PK PRIMARY KEY (ID_EPIS_DIAGNOSIS_HIST, ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS) USING INDEX TABLESPACE ALERT_IDX');
    END set_diag_stag_col_pk;

    PROCEDURE add_diag_stag_col_to_pfact_tbl IS
        l_proc_name CONSTANT VARCHAR2(50 CHAR) := 'ADD_DIAG_STAG_COL_TO_PFACT_TBL';
    BEGIN
        --EPIS_DIAG_STAG_PFACT
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_PFACT ADD ID_STAGING_BASIS NUMBER(24) NOT NULL');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_PFACT ADD ID_SBASIS_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL');
        --EPIS_DSTAG_PFACT_HIST
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DSTAG_PFACT_HIST ADD ID_STAGING_BASIS NUMBER(24) NOT NULL');
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DSTAG_PFACT_HIST ADD ID_SBASIS_INST_OWNER NUMBER(24) DEFAULT 0 NOT NULL');
    END add_diag_stag_col_to_pfact_tbl;

    PROCEDURE add_pfact_pk IS
        l_proc_name CONSTANT VARCHAR2(50 CHAR) := 'ADD_PFACT_PK';
    BEGIN
        --EPIS_DIAG_STAG_PFACT
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_PFACT ADD CONSTRAINT EDSPF_PK PRIMARY KEY (ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS, ID_FIELD, ID_FIELD_INST_OWNER) USING INDEX TABLESPACE ALERT_IDX');
        --EPIS_DSTAG_PFACT_HIST
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DSTAG_PFACT_HIST ADD CONSTRAINT EDSPFH_PK PRIMARY KEY (ID_EPIS_DIAGNOSIS_HIST, ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS, ID_FIELD, ID_FIELD_INST_OWNER) USING INDEX TABLESPACE ALERT_IDX');
    END add_pfact_pk;

    PROCEDURE add_pfact_fk IS
        l_proc_name CONSTANT VARCHAR2(50 CHAR) := 'ADD_PFACT_FK';
    BEGIN
        --EPIS_DIAG_STAG_PFACT
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DIAG_STAG_PFACT ADD CONSTRAINT EDSPF_EDSTGG_FK FOREIGN KEY(ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS) REFERENCES EPIS_DIAG_STAG(ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS)');
        --EPIS_DSTAG_PFACT_HIST
        run_script(i_call_obj_name => l_proc_name,
                   i_script        => 'ALTER TABLE EPIS_DSTAG_PFACT_HIST ADD CONSTRAINT EDSPFH_EDSTGGH_FK FOREIGN KEY(ID_EPIS_DIAGNOSIS_HIST, ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS) REFERENCES EPIS_DIAG_STAG_HIST(ID_EPIS_DIAGNOSIS_HIST, ID_EPIS_DIAGNOSIS, ID_STAGING_BASIS, ID_SBASIS_INST_OWNER, NUM_STAGING_BASIS)');
    END add_pfact_fk;
BEGIN
    clean_invalid_records;

    set_diag_stag_col_not_null;

    set_diag_stag_col_pk;

    add_diag_stag_col_to_pfact_tbl;

    add_pfact_pk;

    add_pfact_fk;
END;
/
