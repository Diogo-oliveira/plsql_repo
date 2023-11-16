DECLARE
    e_cns_already_dropped EXCEPTION;
    e_col_already_dropped EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(e_cns_already_dropped, -2443);
    PRAGMA EXCEPTION_INIT(e_col_already_dropped, -2443);
    
    l_count pls_integer;
BEGIN
    BEGIN
           EXECUTE IMMEDIATE 'ALTER TABLE EPIS_DIAGNOSIS DROP CONSTRAINT EDS_EDN_FK';
    EXCEPTION
        WHEN e_cns_already_dropped THEN
            dbms_output.put_line('AVISO: Operação já executada anteriormente.');
    END;
    BEGIN
           EXECUTE IMMEDIATE 'ALTER TABLE EPIS_DIAGNOSIS_HIST DROP CONSTRAINT EDH_EDN_FK';
    EXCEPTION
        WHEN e_cns_already_dropped THEN
            dbms_output.put_line('AVISO: Operação já executada anteriormente.');
    END;
    
    SELECT COUNT(*)
      INTO l_count
      FROM all_tab_columns a
     WHERE a.owner = 'ALERT'
       AND a.table_name = 'EPIS_DIAGNOSIS_NOTES'
       AND a.column_name = 'ADW_LAST_UPDATE';

    IF l_count = 1 THEN
      --FILL DT_EPIS_DIAGNOSIS_NOTES COLUMN
      EXECUTE IMMEDIATE 'UPDATE EPIS_DIAGNOSIS_NOTES EDN SET EDN.DT_EPIS_DIAGNOSIS_NOTES = EDN.ADW_LAST_UPDATE, EDN.DT_CREATE = EDN.ADW_LAST_UPDATE';
      
      --DELETE EPIS_DIAGNOSIS_NOTES INVALID RECORDS
      EXECUTE IMMEDIATE '
      DELETE FROM epis_diagnosis_notes
       WHERE id_epis_diagnosis_notes IN
             (SELECT t.id_epis_diagnosis_notes
                FROM (SELECT edn.id_epis_diagnosis_notes,
                             (SELECT DISTINCT ed.id_episode
                                FROM epis_diagnosis ed
                                LEFT JOIN epis_diagnosis_hist edh ON edh.id_epis_diagnosis = ed.id_epis_diagnosis
                               WHERE edn.id_epis_diagnosis_notes IN (ed.id_epis_diagnosis_notes, edh.id_epis_diagnosis_notes)) id_episode
                        FROM epis_diagnosis_notes edn) t
               WHERE t.id_episode IS NULL)';

      --FILL ID_EPISODE COLUMN
      EXECUTE IMMEDIATE '
      UPDATE epis_diagnosis_notes edn
         SET edn.id_episode =
             (SELECT DISTINCT ed.id_episode
                FROM epis_diagnosis ed
                LEFT JOIN epis_diagnosis_hist edh ON edh.id_epis_diagnosis = ed.id_epis_diagnosis
               WHERE edn.id_epis_diagnosis_notes IN (ed.id_epis_diagnosis_notes, edh.id_epis_diagnosis_notes))';
       
      --FILL ID_PROF_CREATE COLUMN
      EXECUTE IMMEDIATE '
      MERGE INTO epis_diagnosis_notes edn
      USING (
          WITH tbl_aux AS
           (SELECT ed.id_epis_diagnosis_notes,
                   ed.id_professional_diag    id_professional,
                   ed.dt_epis_diagnosis_tstz  dt_creation_tstz
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis_notes IS NOT NULL
               AND ed.id_professional_diag IS NOT NULL
               AND ed.dt_epis_diagnosis_tstz IS NOT NULL
            UNION ALL
            SELECT ed.id_epis_diagnosis_notes, ed.id_prof_confirmed id_professional, ed.dt_confirmed_tstz dt_creation_tstz
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis_notes IS NOT NULL
               AND ed.id_prof_confirmed IS NOT NULL
               AND ed.dt_confirmed_tstz IS NOT NULL
            UNION ALL
            SELECT ed.id_epis_diagnosis_notes, ed.id_prof_rulled_out id_professional, ed.dt_rulled_out_tstz dt_creation_tstz
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis_notes IS NOT NULL
               AND ed.id_prof_rulled_out IS NOT NULL
               AND ed.dt_rulled_out_tstz IS NOT NULL
            UNION ALL
            SELECT ed.id_epis_diagnosis_notes, ed.id_prof_base id_professional, ed.dt_base_tstz dt_creation_tstz
              FROM epis_diagnosis ed
             WHERE ed.id_epis_diagnosis_notes IS NOT NULL
               AND ed.id_prof_base IS NOT NULL
               AND ed.dt_base_tstz IS NOT NULL
            UNION ALL
            SELECT edh.id_epis_diagnosis_notes, edh.id_professional, edh.dt_creation_tstz
              FROM epis_diagnosis_hist edh
             WHERE edh.id_epis_diagnosis_notes IS NOT NULL)
          SELECT DISTINCT t2.id_epis_diagnosis_notes, t2.id_professional, t2.dt_creation_tstz
            FROM tbl_aux t2
            JOIN (SELECT t.id_epis_diagnosis_notes, MIN(t.dt_creation_tstz) dt_creation_tstz
                    FROM tbl_aux t
                   GROUP BY t.id_epis_diagnosis_notes) t3 ON t3.id_epis_diagnosis_notes = t2.id_epis_diagnosis_notes
                                                         AND t3.dt_creation_tstz = t2.dt_creation_tstz) aux --
           ON (aux.id_epis_diagnosis_notes = edn.id_epis_diagnosis_notes) --
           WHEN MATCHED THEN
              UPDATE
                 SET edn.id_prof_create = aux.id_professional';

      EXECUTE IMMEDIATE '
      UPDATE epis_diagnosis_notes edn
         SET edn.id_prof_create = -1
       WHERE edn.id_prof_create IS NULL';    

      BEGIN
             EXECUTE IMMEDIATE 'ALTER TABLE EPIS_DIAGNOSIS_NOTES DROP COLUMN FLG_AVAILABLE';
      EXCEPTION
          WHEN e_col_already_dropped THEN
              dbms_output.put_line('AVISO: Operação já executada anteriormente.');
      END;
      BEGIN
             EXECUTE IMMEDIATE 'ALTER TABLE EPIS_DIAGNOSIS_NOTES DROP COLUMN ADW_LAST_UPDATE';
      EXCEPTION
          WHEN e_col_already_dropped THEN
              dbms_output.put_line('AVISO: Operação já executada anteriormente.');
      END;
    END IF;
END;
/
