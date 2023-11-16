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

    run_ddl(i_sql => 'DROP MATERIALIZED VIEW STT_REV_SAV_TRANSLATION_UPD PRESERVE TABLE');
    run_ddl(i_sql => 'DROP MATERIALIZED VIEW STT_REV_SAV_TRANSLATION_INS PRESERVE TABLE');

    run_ddl(i_sql => 'DROP MATERIALIZED VIEW STT_REV_SAV_SAMPLE_TEXT PRESERVE TABLE');
    run_ddl(i_sql => 'DROP MATERIALIZED VIEW STT_REV_SAV_SAMPLE_TEXT_TYPE PRESERVE TABLE');
    run_ddl(i_sql => 'DROP MATERIALIZED VIEW STT_REV_SAV_STTC_DEL PRESERVE TABLE');
    run_ddl(i_sql => 'DROP MATERIALIZED VIEW STT_REV_SAV_STTC_INS PRESERVE TABLE');

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/
