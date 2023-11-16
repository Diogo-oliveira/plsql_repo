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

    run_ddl(i_sql => 'drop type t_coll_episode_diagnosis');

    run_ddl(i_sql => 'drop type t_rec_episode_diagnosis');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_rec_episode_diagnosis force AS OBJECT
(
    id_epis_diagnosis     NUMBER(24),
    id_diagnosis          NUMBER(24),
    id_alert_diagnosis    NUMBER(24),
    desc_diagnosis        VARCHAR(1000 CHAR),
    dt_initial_diag       TIMESTAMP WITH LOCAL TIME ZONE,
    dt_initial_diag_chr   VARCHAR2(200 CHAR),
    flg_status            VARCHAR2(1 CHAR),
    desc_status           VARCHAR2(200 CHAR),
    dt_epis_diagnosis     TIMESTAMP WITH LOCAL TIME ZONE,
    dt_epis_diagnosis_chr VARCHAR2(200 CHAR),
    id_prof_diagnosis     NUMBER(24),
    name_prof_diag        VARCHAR2(200 CHAR),
    spec_prof_diag        VARCHAR(1000 CHAR),
    flg_type              VARCHAR2(200 CHAR),
    flg_previous          VARCHAR2(1 CHAR),
    notes                 VARCHAR2(4000),
    flg_other             VARCHAR2(1 CHAR),
    id_content            VARCHAR2(200 CHAR),
    rank                  NUMBER,
    id_episode            NUMBER(24)
)
 ');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_coll_episode_diagnosis AS TABLE OF t_rec_episode_diagnosis');

END;
/
