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

    run_ddl(i_sql => 'drop type t_table_sys_list');

    run_ddl(i_sql => 'drop type t_rec_sys_list');

    run_ddl(i_sql => '  
CREATE OR REPLACE TYPE t_rec_sys_list IS OBJECT
(
    id_sys_list_group NUMBER(24),
    internal_name     VARCHAR2(200 CHAR),
    id_sys_list       NUMBER(24),
    desc_list         VARCHAR2(4000 CHAR),
    img_name          VARCHAR2(200 CHAR),
    rank              NUMBER(6),
		flg_context       VARCHAR2(2 CHAR),
		sys_list_internal_name     VARCHAR2(200 CHAR)
)');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_table_sys_list IS TABLE OF t_rec_sys_list');

END;
/