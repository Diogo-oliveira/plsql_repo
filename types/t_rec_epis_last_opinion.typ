
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
run_ddl(i_sql => '
CREATE OR REPLACE TYPE t_rec_epis_last_opinion force AS OBJECT
(

    id_opinion        NUMBER(24),
    dt_problem_tstz   TIMESTAMP(6) WITH LOCAL TIME ZONE,
    status_string     VARCHAR2(100 CHAR),
    sys_domain_called VARCHAR2(200 CHAR),
    rank              NUMBER(6),

    CONSTRUCTOR FUNCTION t_rec_epis_last_opinion RETURN SELF AS RESULT
)
');

run_ddl(i_sql => 'CREATE OR REPLACE TYPE BODY t_rec_epis_last_opinion IS
    CONSTRUCTOR FUNCTION t_rec_epis_last_opinion RETURN SELF AS RESULT IS
    BEGIN
        SELF.id_opinion   := NULL;

        SELF.dt_problem_tstz    := NULL;
        SELF.status_string  := NULL;
        SELF.sys_domain_called    := NULL;
        SELF.rank := NULL;
       
        RETURN;
    END;
END;
');
END;
/