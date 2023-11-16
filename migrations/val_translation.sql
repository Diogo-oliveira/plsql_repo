DECLARE
    /* Leave as is */
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    /* Leave as is */
    PROCEDURE announce_error IS
    BEGIN
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION'' section. Example:
select *
  from alertlog.tlog
 where lsection = ''MIGRATION''
 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    /* Leave as is */
    FUNCTION should_execute RETURN BOOLEAN IS
    BEGIN
        RETURN &exec_val = 1;
    END should_execute;

    /* Edit this function */
    PROCEDURE do_my_validation IS
        /* Declarations */

        TABLES_NOT_IDENTICAL   EXCEPTION;
        NO_PRIMARY_KEY_CREATED EXCEPTION;
        	MISSING_PRIVILEGES	 EXCEPTION;
        		MISSING_TABLES		 EXCEPTION;
        			MISSING_TYPE			exception;
        l_gridtask_ids table_varchar;
        
        l_sql								varchar2(4000);
        
        l_count_tbl_new			number(24);
        l_count_tbl_old			number(24);
        l_count_trl_new			number(24);
        l_count_trl_old			number(24);
        L_COUNT_PK					NUMBER(24);
        L_COUNT_PRIVS_OLD				NUMBER(24);
        L_COUNT_PRIVS_NEW				NUMBER(24);
        L_COUNT_TYPE						NUMBER(24);
        
    BEGIN
        /* Initializations */
    		/* Table validation */
    		SELECT COUNT(1) INTO L_COUNT_TBL_OLD FROM ALL_TABLES WHERE TABLE_NAME = 'TRANSLATION_BCK_2604' AND OWNER = 'ALERT';
    		SELECT COUNT(1) INTO L_COUNT_TBL_NEW FROM ALL_TABLES WHERE TABLE_NAME = 'TRANSLATION' AND OWNER = 'ALERT';
    
    
    		IF L_COUNT_TBL_OLD != L_COUNT_TBL_NEW THEN
    			RAISE MISSING_TABLES;
    		ELSE
    
	        /* Data validation */
	        l_sql :='select count(1) from ( select code_translation  from translation_bck_2604 group by code_translation )';
					execute immediate l_sql into l_count_trl_old;

	        l_sql :='select count(1) from translation';
					execute immediate l_sql into l_count_trl_new;

	    		if l_count_trl_new != l_count_trl_old then
	    			
	    			/* use exception raising to treat each finding: */
	            RAISE TABLES_NOT_IDENTICAL;    			
	    		end if;
					    		
			  END IF;

				/* CONSTRAINT VALIDATION */    
    		SELECT COUNT(1) INTO L_COUNT_PK FROM ALL_CONSTRAINTS 
    		WHERE CONSTRAINT_NAME = 'TRNSLTN_PK' AND OWNER = 'ALERT';
    
    		IF L_COUNT_PK = 0 THEN RAISE NO_PRIMARY_KEY_CREATED; END IF;
    		
    		
    		/* PRIVILEGES VALIDATION */
    		SELECT COUNT(1) INTO L_COUNT_PRIVS_OLD FROM ALL_TAB_PRIVS WHERE TABLE_NAME = 'TRANSLATION_BCK_2604' AND GRANTEE != 'ALERT';
    		SELECT COUNT(1) INTO L_COUNT_PRIVS_NEW FROM ALL_TAB_PRIVS WHERE TABLE_NAME = 'TRANSLATION' AND GRANTEE != 'ALERT';
    		
    		IF L_COUNT_PRIVS_OLD != L_COUNT_PRIVS_NEW THEN
    			RAISE MISSING_PRIVILEGES;
    		END IF;
    		
    		/* TYPE VALIDATION */
    		SELECT COUNT(1) INTO L_COUNT_TYPE FROM ALL_OBJECTS WHERE OBJECT_NAME  = 'T_SEARCH' AND OWNER = 'ALERT';
    		IF L_COUNT_TYPE = 0 THEN
    				RAISE MISSING_TYPE;
    		END IF;
    
    EXCEPTION
        /* Exceptions handling */
        WHEN TABLES_NOT_IDENTICAL THEN
                log_error( 'MIGRATION ERROR: WRONG NUMBER OF RECORDS IN NEW TABLE' );
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN NO_PRIMARY_KEY_CREATED THEN
                log_error( 'MIGRATION ERROR: PRIMARY KEY NOT CREATED ' );
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN MISSING_PRIVILEGES THEN
                log_error( 'MIGRATION ERROR: Missing Privileges ' );
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN MISSING_TABLES THEN
                log_error( 'MIGRATION ERROR: Missing TABLES ' );
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN MISSING_TYPE THEN
                log_error( 'MIGRATION ERROR: Missing TYPE ' );
            /* in the end call announce_error to warn the installation script */
            announce_error;
    END do_my_validation;

BEGIN
    /* Leave as is */
    IF should_execute
    THEN
        do_my_validation;
    END IF;

EXCEPTION
    /* Leave as is */
    WHEN OTHERS THEN
        log_error('UNEXPECTED ERROR: ' || SQLERRM);
        announce_error;
END;
/


