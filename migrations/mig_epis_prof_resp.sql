-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 11/01/2011 17:03
-- CHANGE REASON: [ALERT-154287] Issue Replication: NL Hand-off problems
DECLARE
    g_bck_alias CONSTANT VARCHAR2(10) := '_BCK1101';
    l_tbl_epr VARCHAR2(32767);

    PROCEDURE backup_responsability(i_tbl_epr IN VARCHAR2) IS
        l_sql VARCHAR2(32767);
    BEGIN
        l_sql := '' || --
                 'CREATE TABLE EPIS_PROF_RESP' || g_bck_alias || ' AS ' || --
                 'SELECT * ' || --
                 'FROM EPIS_PROF_RESP EPR ' || --
                 'WHERE EPR.ID_EPIS_PROF_RESP IN (' || i_tbl_epr || ')';
    
        EXECUTE IMMEDIATE l_sql;
    
        l_sql := '' || --
                 'CREATE TABLE EPIS_MULTI_PROF_RESP' || g_bck_alias || ' AS ' || --
                 'SELECT * ' || --
                 'FROM EPIS_MULTI_PROF_RESP EMPR ' || --
                 'WHERE EMPR.ID_EPIS_PROF_RESP IN (' || i_tbl_epr || ')';
    
        EXECUTE IMMEDIATE l_sql;
    
        l_sql := '' || --
                 'CREATE TABLE EPIS_MPROFRESP_HIST' || g_bck_alias || ' AS ' || --
                 'SELECT * ' || --
                 'FROM EPIS_MULTI_PROFRESP_HIST EMPR ' || --
                 'WHERE EMPR.ID_EPIS_PROF_RESP IN (' || i_tbl_epr || ')';
    
        EXECUTE IMMEDIATE l_sql;
    END backup_responsability;

    PROCEDURE delete_resp(i_tbl_epr IN VARCHAR2) IS
    BEGIN
        --DELETE EPIS_MULTI_PROFRESP_HIST
        DELETE FROM epis_multi_profresp_hist emprh
         WHERE emprh.id_epis_prof_resp IN
               (SELECT column_value
                  FROM TABLE(pk_utils.str_split_l(i_tbl_epr, ',')));
    
        --DELETE EPIS_MULTI_PROF_RESP
        DELETE FROM epis_multi_prof_resp empr
         WHERE empr.id_epis_prof_resp IN (SELECT column_value
                                            FROM TABLE(pk_utils.str_split_l(i_tbl_epr, ',')));
    
        --DELETE EPIS_PROF_RESP
        DELETE FROM epis_prof_resp epr
         WHERE epr.id_epis_prof_resp IN (SELECT column_value
                                           FROM TABLE(pk_utils.str_split_l(i_tbl_epr, ',')));
    END delete_resp;
BEGIN
    --GET ALL EPISODE RESPONSABILITIES THAT EXISTS IN OUTP EPISODES
    SELECT pk_utils.concat_table(CAST(MULTISET
                                      (SELECT epr.id_epis_prof_resp
                                         FROM epis_prof_resp epr
                                         JOIN epis_info ei ON ei.id_episode = epr.id_episode
                                        WHERE ei.id_software = 1
                                          AND NOT EXISTS (SELECT *
                                                 FROM epis_multi_prof_resp empr
                                                WHERE empr.id_epis_prof_resp = epr.id_epis_prof_resp
                                                  AND empr.flg_resp_type = 'O')) AS table_varchar),
                                 ',')
      INTO l_tbl_epr
      FROM dual;

    --BACKUP RESPONSABILITIES TABLE's
    backup_responsability(i_tbl_epr => l_tbl_epr);

    -- DELETE ALL EPISODE RESPONSABILITIES RECORDS
    delete_resp(i_tbl_epr => l_tbl_epr);
END;
/
-- CHANGE END: Alexandre Santos