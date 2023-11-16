DECLARE
    g_mess   VARCHAR2(4000);
    col_type VARCHAR2(50);
    g_exception EXCEPTION;
    c NUMBER;

    PROCEDURE announce_error(i_message VARCHAR2) IS
    BEGIN
        dbms_output.put_line(current_timestamp || ': E R R O R : ' || i_message);
        dbms_output.put_line(' :SQLCODE: ' || SQLCODE || ' :SQLERRM: ' || SQLERRM);
        dbms_output.put_line(' :ERROR_STACK: ' || dbms_utility.format_error_stack || ' :ERROR_BACKTRACE: ' ||
                             dbms_utility.format_error_backtrace || ' :CALL_STACK: ' || dbms_utility.format_call_stack);
    END announce_error;

    PROCEDURE log_reg(i_message VARCHAR2) IS
    BEGIN
        dbms_output.put_line(current_timestamp || ': L O G : ' || i_message);
    END log_reg;

BEGIN
    log_reg('Start migration for drug_protocols.id_drug ...');

    SELECT COUNT(1)
      INTO c
      FROM all_constraints atc
     WHERE lower(atc.constraint_name) = 'dps_drug_fk'
       AND lower(atc.owner) = 'alert';

    IF c > 0
    THEN
        -- constraint exists, drop it
        g_mess := 'remove constraint dps_drug_fk';
        EXECUTE IMMEDIATE 'ALTER TABLE alert.drug_protocols drop CONSTRAINT dps_drug_fk';
        log_reg('constraint dropped');
    ELSE
        log_reg('no constraint to drop');
    END IF;

    SELECT atc.data_type
      INTO col_type
      FROM all_tab_cols atc
     WHERE lower(atc.table_name) = 'drug_protocols'
       AND lower(atc.column_name) = 'id_drug'
       AND lower(atc.owner) = 'alert';

    g_mess := 'test column for possible previous migration';
    IF col_type = 'NUMBER'
    THEN
        g_mess := 'test column''s values to check if a new column is needed';
        SELECT COUNT(1)
          INTO c
          FROM drug_protocols dp
         WHERE dp.id_drug IS NOT NULL;
    
        IF c > 0
        THEN
            g_mess := 'if count > 0 a new column is needed';
            EXECUTE IMMEDIATE 'ALTER TABLE drug_protocols rename column id_drug TO id_drug_duplicate';
        
            g_mess := 'alter table, add new column id_drug';
            EXECUTE IMMEDIATE 'ALTER TABLE drug_protocols add(id_drug VARCHAR2(255))';
        
            g_mess := 'new column comment';
            EXECUTE IMMEDIATE 'COMMENT ON COLUMN alert.DRUG_PROTOCOLS.id_drug  is ''ID do medicamento''';
        
            g_mess := 'update new column with dml data';
            EXECUTE IMMEDIATE 'UPDATE drug_protocols SET id_drug = id_drug_duplicate';
        
            g_mess := 'update new column to be not null';
            EXECUTE IMMEDIATE 'ALTER TABLE drug_protocols MODIFY (id_drug varchar2(255) not null)';
        ELSE
            g_mess := 'change column datatype';
            --  if count = 0, it is not necessary to create a new column
            EXECUTE IMMEDIATE 'ALTER TABLE drug_protocols modify(id_drug VARCHAR2(255))';
        END IF;
    
    ELSE
        log_reg(' there is nothing to migrate ... ');
    END IF;

    log_reg(' checking if vers column exists ... ');
    SELECT COUNT(1)
      INTO c
      FROM all_tab_cols atc
     WHERE lower(atc.table_name) = 'drug_protocols'
       AND lower(atc.column_name) = 'vers'
       AND lower(atc.owner) = 'alert';

    IF c = 0
    THEN
        g_mess := 'alter table, add new column vers';
        EXECUTE IMMEDIATE 'ALTER TABLE drug_protocols add(vers VARCHAR2(255))';
    END IF;

    --add new constraint to correct table
    g_mess := 'create new constraint pointing to mi_med';
    EXECUTE IMMEDIATE 'ALTER TABLE drug_protocols add CONSTRAINT dps_drug_fk foreign key(id_drug, vers) references
                 mi_med(id_drug, vers)';

    log_reg(' .. .end migration for drug_protocols.id_drug. ');

EXCEPTION
    WHEN OTHERS THEN
        announce_error(g_mess);
        ROLLBACK;
END;
