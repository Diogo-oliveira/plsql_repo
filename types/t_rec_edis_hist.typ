CREATE OR REPLACE TYPE t_rec_edis_hist AS OBJECT(
        id_history      NUMBER(24),
        dt_history      TIMESTAMP(6) WITH LOCAL TIME ZONE,
        tbl_labels      table_varchar,
        tbl_values      table_varchar,
        tbl_types       table_varchar,
        tbl_info_labels table_varchar,
        tbl_info_values table_varchar);



DROP TYPE t_table_edis_hist;
DROP TYPE t_rec_edis_hist;

CREATE OR REPLACE TYPE t_rec_edis_hist AS OBJECT(
        id_history      NUMBER(24),
        id_episode      NUMBER(24),
        desc_cat_viewer VARCHAR2(1000 CHAR),
        id_professional NUMBER(24),
        dt_history      TIMESTAMP(6) WITH LOCAL TIME ZONE,
        tbl_labels      table_varchar,
        tbl_values      table_varchar,
        tbl_types       table_varchar,
        tbl_codes       table_varchar,
        tbl_info_labels table_varchar,
        tbl_info_values table_varchar);

CREATE OR REPLACE TYPE t_table_edis_hist IS TABLE OF t_rec_edis_hist;


-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 28/01/2015 17:37
-- CHANGE REASON: [ALERT-307017] [EDIS] DB changes versioning
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

    run_ddl(i_sql => 'drop type t_table_edis_hist');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_rec_edis_hist AS OBJECT(
                                id_history      NUMBER(24),
                                id_episode      NUMBER(24),
                                desc_cat_viewer VARCHAR2(1000 CHAR),
                                id_professional NUMBER(24),
                                dt_history      TIMESTAMP(6) WITH LOCAL TIME ZONE,
                                tbl_labels      table_varchar,
                                tbl_values      table_clob,
                                tbl_types       table_varchar,
                                tbl_codes       table_varchar,
                                tbl_info_labels table_varchar,
                                tbl_info_values table_varchar                        
                       )');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_table_edis_hist IS TABLE OF t_rec_edis_hist');

END;
/
-- CHANGE END:  Gisela Couto

-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 28/01/2015 17:37
-- CHANGE REASON: [ALERT-307017] [EDIS] DB changes versioning
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

    run_ddl(i_sql => 'drop type t_table_edis_hist');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_rec_edis_hist AS OBJECT(
              id_history      NUMBER(24),
              id_episode      NUMBER(24),
              desc_cat_viewer VARCHAR2(1000 CHAR),
              id_professional NUMBER(24),
              dt_history      TIMESTAMP(6) WITH LOCAL TIME ZONE,
              tbl_labels      table_varchar,
              tbl_values      table_clob,
              tbl_types       table_varchar,
              tbl_codes       table_varchar,
              tbl_info_labels table_varchar,
              tbl_info_values table_varchar                        
     )');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_table_edis_hist IS TABLE OF t_rec_edis_hist');

END;
/