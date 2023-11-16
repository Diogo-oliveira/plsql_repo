-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 31/07/2014 17:15
-- CHANGE REASON: [ALERT-291997] Dev DB - Multichoice domain tables implementation - Migration Script - schema alert
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || replace(SRCSTR => SQLERRM, OLDSUB => 'ORA-', NEWSUB => '') || '; ' || i_sql || ';');
    END run_ddl;

BEGIN


    run_ddl(i_sql => '    MERGE INTO pat_preg_cont_type ppct
    USING (SELECT ROWID,
                  id_pat_pregnancy,
                  flg_contrac_type,
                  (CASE
                       WHEN flg_contrac_type = ''A'' THEN
                        1
                       WHEN flg_contrac_type = ''AC'' THEN
                        2
                       WHEN flg_contrac_type = ''AO'' THEN
                        3
                       WHEN flg_contrac_type = ''C'' THEN
                        4
                       WHEN flg_contrac_type = ''CE'' THEN
                        5
                       WHEN flg_contrac_type = ''D'' THEN
                        6
                       WHEN flg_contrac_type = ''E'' THEN
                        7
                       WHEN flg_contrac_type = ''I'' THEN
                        8
                       WHEN flg_contrac_type = ''IM'' THEN
                        9
                       WHEN flg_contrac_type = ''MB'' THEN
                        10
                       WHEN flg_contrac_type = ''MN'' THEN
                        11
                       WHEN flg_contrac_type = ''O'' THEN
                        -1
                       WHEN flg_contrac_type = ''P'' THEN
                        12
                       WHEN flg_contrac_type = ''PF'' THEN
                        13
                       WHEN flg_contrac_type = ''PI'' THEN
                        14
                       WHEN flg_contrac_type = ''PM'' THEN
                        15
                       WHEN flg_contrac_type = ''SI'' THEN
                        16
                   END) id_option
             FROM pat_preg_cont_type) ppct1
    ON (ppct.rowid = ppct1.rowid)
    WHEN MATCHED THEN
        UPDATE
           SET ppct.id_contrac_type = ppct1.id_option');
 
END;
/
-- CHANGE END:  Gisela Couto

-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 10/09/2014 16:05
-- CHANGE REASON: [ALERT-294272] Pregnancy button - Create a current pregnancy record - Document information and save - An error occurs
DECLARE
    l_multichoice_option_cnt NUMBER;
    l_column_exists NUMBER;
    l_tbl_dup_vals           table_number;
BEGIN

    BEGIN
        SELECT COUNT(0)
          INTO l_column_exists
          FROM dba_tab_cols dba
         WHERE dba.column_name = 'FLG_CONTRAC_TYPE'
           AND dba.table_name = 'PAT_PREG_CONT_TYPE';
    EXCEPTION
        WHEN no_data_found THEN
            l_column_exists := 0;
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ');
    END;

    IF (l_column_exists <> 0)
    THEN
        BEGIN
            SELECT COUNT(0)
              INTO l_multichoice_option_cnt
              FROM alert_core_data.multichoice_option mo
             WHERE mo.id_multichoice_option IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, -1);
        EXCEPTION
            WHEN no_data_found THEN
                l_multichoice_option_cnt := 0;
            WHEN OTHERS THEN
                dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ');
        END;
    
        IF (l_multichoice_option_cnt <> 17)
        THEN
            raise_application_error(-20101,
                                    'ALERT_CORE_DATA.MULTICHOICE_OPTION TABLE DOESN''T HAVE ALL DATA TO CONTINUE MIGRATION PROCESS.');
        ELSE
        
            BEGIN
              execute immediate 'MERGE INTO pat_preg_cont_type ppct
                USING (SELECT ROWID,
                              id_pat_pregnancy,
                              flg_contrac_type,
                              (CASE
                                   WHEN flg_contrac_type = ''A'' THEN
                                    1
                                   WHEN flg_contrac_type = ''AC'' THEN
                                    2
                                   WHEN flg_contrac_type = ''AO'' THEN
                                    3
                                   WHEN flg_contrac_type = ''C'' THEN
                                    4
                                   WHEN flg_contrac_type = ''CE'' THEN
                                    5
                                   WHEN flg_contrac_type = ''D'' THEN
                                    6
                                   WHEN flg_contrac_type = ''E'' THEN
                                    7
                                   WHEN flg_contrac_type = ''I'' THEN
                                    8
                                   WHEN flg_contrac_type = ''IM'' THEN
                                    9
                                   WHEN flg_contrac_type = ''MB'' THEN
                                    10
                                   WHEN flg_contrac_type = ''MN'' THEN
                                    11
                                   WHEN flg_contrac_type = ''O'' THEN
                                    -1
                                   WHEN flg_contrac_type = ''P'' THEN
                                    12
                                   WHEN flg_contrac_type = ''PF'' THEN
                                    13
                                   WHEN flg_contrac_type = ''PI'' THEN
                                    14
                                   WHEN flg_contrac_type = ''PM'' THEN
                                    15
                                   WHEN flg_contrac_type = ''SI'' THEN
                                    16
                                   ELSE
                                    -1

                               END) id_option
                         FROM pat_preg_cont_type) ppct1
                ON (ppct.rowid = ppct1.rowid)
                WHEN MATCHED THEN
                    UPDATE
                       SET ppct.id_contrac_type = ppct1.id_option';
            
            EXCEPTION
            
                WHEN OTHERS THEN
                    dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ');
            END;
        
        END IF;
    ELSE
        BEGIN
        
            SELECT ppct.id_pat_pregnancy BULK COLLECT
              INTO l_tbl_dup_vals
              FROM alert.pat_preg_cont_type ppct
             WHERE nvl(ppct.id_contrac_type, -1) = -1
             GROUP BY ppct.id_pat_pregnancy
            HAVING COUNT(ppct.id_pat_pregnancy) > 1;
        
            IF l_tbl_dup_vals.exists(1)
            THEN
                FOR i IN l_tbl_dup_vals.first .. l_tbl_dup_vals.last
                LOOP
                
                    DELETE FROM alert.pat_preg_cont_type ppct
                     WHERE ppct.rowid IN (SELECT t.pk
                                             FROM (SELECT ppct1.rowid pk, rownum ln
                                                     FROM alert.pat_preg_cont_type ppct1
                                                    WHERE ppct1.id_pat_pregnancy = l_tbl_dup_vals(i)) t
                                            WHERE t.ln > 1);
                END LOOP;

            END IF;
        
    execute immediate 'MERGE INTO pat_preg_cont_type ppct
                USING (SELECT id_pat_pregnancy
                         FROM pat_preg_cont_type 
 WHERE id_contrac_type IS NULL) ppct1
                ON (ppct.id_pat_pregnancy = ppct1.id_pat_pregnancy)
                WHEN MATCHED THEN
                    UPDATE
                       SET ppct.id_contrac_type = -1';

        EXCEPTION
        
            WHEN OTHERS THEN
                dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ');
        END;
    
    END IF;

END;
/
-- CHANGE END:  Gisela Couto