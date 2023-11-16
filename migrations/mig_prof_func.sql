-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 17/10/2014 15:56
-- CHANGE REASON: [ALERT-298852] 
DECLARE
    l_error VARCHAR2(1000 CHAR);
    l_count PLS_INTEGER;

    CURSOR c_sys_func IS
        SELECT sf.id_functionality AS id_functionality,
               ppt.id_professional AS id_professional,
               ppt.id_institution  AS id_institution
          FROM sys_func_category sc
          JOIN sys_functionality sf
            ON sf.id_functionality = sc.id_sys_functionality
          JOIN profile_template pt
            ON (pt.id_category = sc.id_category AND pt.id_software = sf.id_software)
          JOIN prof_profile_template ppt
            ON (ppt.id_profile_template = pt.id_profile_template)
         WHERE sf.intern_name_func IN ('PRINT_LIST_CAN_PRINT', 'PRINT_LIST_CAN_ADD')
           AND sc.flg_available = pk_alert_constant.g_yes
           AND NOT EXISTS (SELECT 1 -- nao insere 2x
                  FROM prof_func pf
                 WHERE pf.id_functionality = sf.id_functionality
                   AND pf.id_professional = ppt.id_professional
                   AND pf.id_institution = ppt.id_institution);

    TYPE t_sys_func IS TABLE OF c_sys_func%ROWTYPE;
    l_coll_sys_func t_sys_func;

    l_limit PLS_INTEGER := 2000;

    l_errors PLS_INTEGER;
    e_dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dml_errors, -24381);
BEGIN

    l_error := 'OPEN c_sys_func';
    OPEN c_sys_func;
    LOOP
    
        l_error := 'FETCH c_sys_func BULK COLLECT';
        FETCH c_sys_func BULK COLLECT
            INTO l_coll_sys_func LIMIT l_limit;
    
        l_error := 'FETCH c_sys_func BULK COLLECT';
        FORALL i IN 1 .. l_coll_sys_func.count SAVE EXCEPTIONS
            INSERT INTO prof_func
                (id_prof_func, id_functionality, id_professional, id_institution)
            VALUES
                (seq_prof_func.nextval,
                 l_coll_sys_func(i).id_functionality,
                 l_coll_sys_func(i).id_professional,
                 l_coll_sys_func(i).id_institution);
        COMMIT;
    
        dbms_output.put_line('Registos inseridos=' || l_coll_sys_func.count);
    
        EXIT WHEN l_coll_sys_func.count < l_limit;
    
    END LOOP;
    CLOSE c_sys_func;

EXCEPTION
    WHEN e_dml_errors THEN
        COMMIT;
        l_errors := SQL%bulk_exceptions.count;
        dbms_output.put_line('Number of DELETE statements that failed: ' || l_errors);
    
        FOR i IN 1 .. l_errors
        LOOP
            dbms_output.put_line('ID_FUNC=' || l_coll_sys_func(SQL%BULK_EXCEPTIONS(i).error_index).id_functionality ||
                                 ' ID_PROF=' || l_coll_sys_func(SQL%BULK_EXCEPTIONS(i).error_index).id_professional ||
                                 ' ID_INST=' || l_coll_sys_func(SQL%BULK_EXCEPTIONS(i).error_index).id_institution);
            dbms_output.put_line('Error message is ' || SQLERRM(-sql%BULK_EXCEPTIONS(i).error_code));
        END LOOP;
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(SQLERRM);
END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 21/10/2014 15:57
-- CHANGE REASON: [ALERT-299240] 
DECLARE
    l_error VARCHAR2(1000 CHAR);
    l_count PLS_INTEGER;

    CURSOR c_sys_func IS
        SELECT sf.id_functionality AS id_functionality,
               ppt.id_professional AS id_professional,
               ppt.id_institution  AS id_institution
          FROM sys_func_category sc
          JOIN sys_functionality sf
            ON sf.id_functionality = sc.id_sys_functionality
          JOIN profile_template pt
            ON (pt.id_category = sc.id_category AND pt.id_software = sf.id_software)
          JOIN prof_profile_template ppt
            ON (ppt.id_profile_template = pt.id_profile_template)
         WHERE sf.intern_name_func IN ('PRINT_LIST_CAN_PRINT', 'PRINT_LIST_CAN_ADD')
           AND sc.flg_available = pk_alert_constant.g_yes
           AND NOT EXISTS (SELECT 1 -- nao insere 2x
                  FROM prof_func pf
                 WHERE pf.id_functionality = sf.id_functionality
                   AND pf.id_professional = ppt.id_professional
                   AND pf.id_institution = ppt.id_institution);

    TYPE t_sys_func IS TABLE OF c_sys_func%ROWTYPE;
    l_coll_sys_func t_sys_func;

    l_limit PLS_INTEGER := 2000;

    l_errors PLS_INTEGER;
    e_dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_dml_errors, -24381);
BEGIN

    l_error := 'OPEN c_sys_func';
    OPEN c_sys_func;
    LOOP
    
        l_error := 'FETCH c_sys_func BULK COLLECT';
        FETCH c_sys_func BULK COLLECT
            INTO l_coll_sys_func LIMIT l_limit;
    
        l_error := 'FETCH c_sys_func BULK COLLECT';
        FORALL i IN 1 .. l_coll_sys_func.count SAVE EXCEPTIONS
            INSERT INTO prof_func
                (id_prof_func, id_functionality, id_professional, id_institution)
            VALUES
                (seq_prof_func.nextval,
                 l_coll_sys_func(i).id_functionality,
                 l_coll_sys_func(i).id_professional,
                 l_coll_sys_func(i).id_institution);
        COMMIT;
    
        dbms_output.put_line('Registos inseridos=' || l_coll_sys_func.count);
    
        EXIT WHEN l_coll_sys_func.count < l_limit;
    
    END LOOP;
    CLOSE c_sys_func;

EXCEPTION
    WHEN e_dml_errors THEN
        COMMIT;
        l_errors := SQL%bulk_exceptions.count;
        dbms_output.put_line('Number of INSERT statements that failed: ' || l_errors);
    
        FOR i IN 1 .. l_errors
        LOOP
            dbms_output.put_line('ID_FUNC=' || l_coll_sys_func(SQL%BULK_EXCEPTIONS(i).error_index).id_functionality ||
                                 ' ID_PROF=' || l_coll_sys_func(SQL%BULK_EXCEPTIONS(i).error_index).id_professional ||
                                 ' ID_INST=' || l_coll_sys_func(SQL%BULK_EXCEPTIONS(i).error_index).id_institution);
            dbms_output.put_line('Error message is ' || SQLERRM(-sql%BULK_EXCEPTIONS(i).error_code));
        END LOOP;
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(SQLERRM);
END;
/
-- CHANGE END: Ana Monteiro