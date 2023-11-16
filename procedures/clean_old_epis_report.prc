i
-- CHANGED BY: Filipe Machado
-- CHANGE DATE: 2009/07/22 10:44
-- CHANGE REASON: ALERT-37218 [[REPORTS] CLEAN_OLD_EPIS_REPORT]
-- CHANGE VERSION: 2.5.0.5

CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

    -- Américo Santos, ALERT, 2007.11.09

    -- Procedimento que elimina os reports NÃO impressos com mais que dois dias
    -- Realizado em concordância com o desenvolvimento (Ricardo Pires)
    -- Executado a partir de um job diário

    CURSOR cepis_report IS
        SELECT ROWID, id_epis_report, adw_last_update
          FROM epis_report
         WHERE flg_status = 'N'
           AND (trunc(SYSDATE) - trunc(adw_last_update)) > 2
           AND rownum < 2000;

    ncount NUMBER(4) := 0;

BEGIN
    FOR ccur IN cepis_report
    LOOP
        BEGIN
            DELETE FROM epis_report_section
             WHERE id_epis_report = ccur.id_epis_report;
            DELETE FROM epis_report
             WHERE ROWID = ccur.ROWID;
        
            ncount := ncount + 1;
        
            IF ncount >= 1000
            THEN
                COMMIT;
                ncount := 0;
            END IF;
        END;
    END LOOP;

    COMMIT;
END;
/

-- CHANGE END: Filipe Machado


-- CHANGED BY: Filipe Machado
-- CHANGE DATE: 2009/07/22 10:44
-- CHANGE REASON: ALERT-37218 [[REPORTS] CLEAN_OLD_EPIS_REPORT]
-- CHANGE VERSION: 2.5.0.5

CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

    -- Américo Santos, ALERT, 2007.11.09

    -- Procedimento que elimina os reports NÃO impressos com mais que dois dias
    -- Realizado em concordância com o desenvolvimento (Ricardo Pires)
    -- Executado a partir de um job diário

    CURSOR cepis_report IS
        SELECT ROWID, id_epis_report, adw_last_update
          FROM epis_report
         WHERE flg_status = 'N'
           AND (trunc(SYSDATE) - trunc(adw_last_update)) > 2
           AND rownum < 2000;

    ncount NUMBER(4) := 0;

BEGIN
    FOR ccur IN cepis_report
    LOOP
        BEGIN
            DELETE FROM epis_report_section
             WHERE id_epis_report = ccur.id_epis_report;
            DELETE FROM epis_report
             WHERE ROWID = ccur.ROWID;
        
            ncount := ncount + 1;
        
            IF ncount >= 1000
            THEN
                COMMIT;
                ncount := 0;
            END IF;
        END;
    END LOOP;

    COMMIT;
END;
/

-- CHANGE END: Filipe Machado

-- CHANGED BY: Tiago Lourenço
-- CHANGE DATE: 2011-10-04
-- CHANGE REASON: [ALERT-198275] Clean old EPIS_REPORT: Don't delete signed reports

CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

    -- Américo Santos, ALERT, 2007.11.09

    -- Procedimento que elimina os reports NÃO impressos com mais que dois dias
    -- Realizado em concordância com o desenvolvimento (Ricardo Pires)
    -- Executado a partir de um job diário

    CURSOR cepis_report IS
        SELECT ROWID, id_epis_report, adw_last_update
          FROM epis_report
         WHERE flg_status = 'N'
           AND flg_signed = 'N'
           AND (trunc(SYSDATE) - trunc(adw_last_update)) > 2
           AND rownum < 2000;

    ncount NUMBER(4) := 0;

BEGIN
    FOR ccur IN cepis_report
    LOOP
        BEGIN
            DELETE FROM epis_report_section
             WHERE id_epis_report = ccur.id_epis_report;
            DELETE FROM epis_report
             WHERE ROWID = ccur.rowid;
        
            ncount := ncount + 1;
        
            IF ncount >= 1000
            THEN
                COMMIT;
                ncount := 0;
            END IF;
        END;
    END LOOP;

    COMMIT;
END;
/

-- CHANGE END: Tiago Lourenço

-- CHANGED BY: ricardo.pires
-- CHANGE DATE: 2013-03-05
-- CHANGE REASON: [ALERT-252915] Update procedure CLEAN_OLD_EPIS_REPORT: delete also epis_report_disclosure
CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

    -- Américo Santos, ALERT, 2007.11.09

    -- Procedimento que elimina os reports NÃO impressos com mais que dois dias
    -- Realizado em concordância com o desenvolvimento (Ricardo Pires)
    -- Executado a partir de um job diário

    CURSOR cepis_report IS
        SELECT ROWID, id_epis_report, adw_last_update
          FROM epis_report
         WHERE flg_status = 'N'
           AND flg_signed = 'N'
           AND (trunc(SYSDATE) - trunc(adw_last_update)) > 2
           AND rownum < 2000;                     

    ncount NUMBER(4) := 0;

BEGIN
    FOR ccur IN cepis_report
    LOOP
        BEGIN
            DELETE FROM epis_report_disclosure
             WHERE id_epis_report = ccur.id_epis_report;             
            DELETE FROM epis_report_section
             WHERE id_epis_report = ccur.id_epis_report;
            DELETE FROM epis_report
             WHERE ROWID = ccur.rowid;
        
            ncount := ncount + 1;
        
            IF ncount >= 1000
            THEN
                COMMIT;
                ncount := 0;
            END IF;
        END;
    END LOOP;

    COMMIT;
END;
/
-- CHANGE END: ricardo.pires

-- CHANGED BY: Ruben Araujo
-- CHANGE DATE: 2016/05/23 08:35
-- CHANGE REASON: ALERT-317047
-- Américo Santos, ALERT, 2007.11.09 
    -- Procedimento que elimina os reports NÃO impressos com mais que dois dias 
    -- Realizado em concordância com o desenvolvimento (Ricardo Pires) 
    -- Executado a partir de um job diário 
CREATE OR REPLACE PROCEDURE alert.clean_old_epis_report IS 	
    CURSOR cepis_report IS 
        SELECT er.rowid, er.id_epis_report, er.adw_last_update 
          FROM alert.epis_report er 
         WHERE er.flg_status = 'N' 
           AND er.flg_signed = 'N' 
           AND NOT EXISTS (SELECT 1 
                  FROM alert.ref_report rr 
                 WHERE rr.id_epis_report = er.id_epis_report 
                   AND rr.flg_type = 'D') 
           AND (trunc(SYSDATE) - trunc(er.adw_last_update)) > 2 
           AND rownum < 2000; 
    ncount NUMBER(4) := 0; 
BEGIN 
    FOR ccur IN cepis_report 
    LOOP 
        BEGIN 
            DELETE FROM epis_report_disclosure 
             WHERE id_epis_report = ccur.id_epis_report; 
            DELETE FROM epis_report_section 
             WHERE id_epis_report = ccur.id_epis_report; 
            DELETE FROM ref_report 
             WHERE id_epis_report = ccur.id_epis_report; 
            UPDATE discharge_notes 
               SET id_epis_report = NULL 
             WHERE id_epis_report = ccur.id_epis_report; 
            UPDATE alert_product_tr.presc_print 
               SET id_epis_report = NULL 
             WHERE id_epis_report = ccur.id_epis_report; 
            DELETE FROM epis_report 
             WHERE ROWID = ccur.rowid; 
            ncount := ncount + 1; 
            IF ncount >= 1000 
            THEN 
                COMMIT; 
                ncount := 0; 
            END IF; 
        END; 
    END LOOP; 
    COMMIT; 
END; 
/
-- CHANGE END: Ruben Araujo


-- CHANGED BY: Ruben Araujo
-- CHANGE DATE: 2016/06/22 14:35
-- CHANGE REASON: ALERT-322373

CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

  -- Procedimento que elimina os registos temporarios na epis_report
  -- Realizado em concordância com o desenvolvimento 
  -- Executado a partir de um job diário

  CURSOR cepis_report IS
    SELECT er.rowid, er.id_epis_report, er.adw_last_update
      FROM alert.epis_report er
     WHERE er.flg_status = 'N'
       AND er.flg_signed = 'N'
       AND NOT EXISTS (SELECT 1
              FROM alert.ref_report rr
             WHERE rr.id_epis_report = er.id_epis_report
               AND rr.flg_type = 'D')
       AND (trunc(SYSDATE) - trunc(er.adw_last_update)) > 2
       AND rownum < 2000
       ORDER BY ER.ID_EPIS_REPORT desc;

  ncount NUMBER(4) := 0;

BEGIN
  FOR ccur IN cepis_report LOOP
    BEGIN
    
        DBMS_OUTPUT.PUT_LINE(ccur.id_epis_report );
        
        DELETE FROM epis_report_disclosure
         WHERE id_epis_report = ccur.id_epis_report;
      
        DELETE FROM epis_report_section
         WHERE id_epis_report = ccur.id_epis_report;
      
        DELETE FROM ref_report WHERE id_epis_report = ccur.id_epis_report;
      
        UPDATE discharge_notes
           SET id_epis_report = NULL
         WHERE id_epis_report = ccur.id_epis_report;
      
        UPDATE alert_product_tr.presc_print
           SET id_epis_report = NULL
         WHERE id_epis_report = ccur.id_epis_report;
         
         UPDATE alert.epis_report e
           SET e.id_epis_parent = NULL
         WHERE e.id_epis_parent = ccur.id_epis_report;
      
        DELETE FROM epis_report WHERE ROWID = ccur.rowid;
      
        ncount := ncount + 1;
      
        IF ncount >= 1000 THEN
          COMMIT;
          ncount := 0;
        END IF;        
    END;
  END LOOP;

  COMMIT;
END;
/
-- CHANGE END: Ruben Araujo


-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 2017/05/11 14:35
-- CHANGE REASON: ALERT-330782

CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

  -- Procedimento que elimina os registos temporarios na epis_report
  -- Realizado em concordância com o desenvolvimento 
  -- Executado a partir de um job diário

  CURSOR cepis_report IS
    SELECT er.rowid, er.id_epis_report, er.adw_last_update
      FROM alert.epis_report er
     WHERE er.flg_status = 'N'
       AND er.flg_signed = 'N'
       AND NOT EXISTS (SELECT 1
              FROM alert.ref_report rr
             WHERE rr.id_epis_report = er.id_epis_report
               AND rr.flg_type = 'D')
	   AND NOT EXISTS (SELECT 1
			        FROM alert.epis_report erp
							WHERE erp.id_epis_parent = er.id_epis_report)
       AND (trunc(SYSDATE) - trunc(er.adw_last_update)) > 2
       AND rownum < 2000
       ORDER BY ER.ID_EPIS_REPORT desc;

  ncount NUMBER(4) := 0;

BEGIN
  FOR ccur IN cepis_report LOOP
    BEGIN
    
        DBMS_OUTPUT.PUT_LINE(ccur.id_epis_report );
        
        DELETE FROM epis_report_disclosure
         WHERE id_epis_report = ccur.id_epis_report;
      
        DELETE FROM epis_report_section
         WHERE id_epis_report = ccur.id_epis_report;
      
        DELETE FROM ref_report WHERE id_epis_report = ccur.id_epis_report;
      
        UPDATE discharge_notes
           SET id_epis_report = NULL
         WHERE id_epis_report = ccur.id_epis_report;
      
        UPDATE alert_product_tr.presc_print
           SET id_epis_report = NULL
         WHERE id_epis_report = ccur.id_epis_report;
         
         UPDATE alert.epis_report e
           SET e.id_epis_parent = NULL
         WHERE e.id_epis_parent = ccur.id_epis_report;
      
        DELETE FROM epis_report WHERE ROWID = ccur.rowid;
      
        ncount := ncount + 1;
      
        IF ncount >= 1000 THEN
          COMMIT;
          ncount := 0;
        END IF;        
    END;
  END LOOP;

  COMMIT;
END;
/
-- CHANGE END: Pedro Henriques


-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 2017/05/17 09:55
-- CHANGE REASON: ALERT-330915

CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

  -- Procedimento que elimina os registos temporarios na epis_report
  -- Realizado em concordância com o desenvolvimento 
  -- Executado a partir de um job diário

  CURSOR cepis_report IS
    SELECT er.rowid, er.id_epis_report, er.adw_last_update
      FROM alert.epis_report er
     WHERE er.flg_status = 'N'
       AND er.flg_signed = 'N'
       AND NOT EXISTS (SELECT 1
              FROM alert.ref_report rr
             WHERE rr.id_epis_report = er.id_epis_report
               AND rr.flg_type = 'D')
	   AND NOT EXISTS (SELECT 1
			        FROM alert.epis_report erp
							WHERE erp.id_epis_parent = er.id_epis_report)
       AND (trunc(SYSDATE) - trunc(er.adw_last_update)) > 2
       ORDER BY ER.ID_EPIS_REPORT desc;

  ncount NUMBER(4) := 0;

BEGIN
  FOR ccur IN cepis_report LOOP
    BEGIN
    
        --DBMS_OUTPUT.PUT_LINE(ccur.id_epis_report );
        
        DELETE FROM epis_report_disclosure
         WHERE id_epis_report = ccur.id_epis_report;
      
        DELETE FROM epis_report_section
         WHERE id_epis_report = ccur.id_epis_report;
      
        DELETE FROM ref_report WHERE id_epis_report = ccur.id_epis_report;
      
        UPDATE discharge_notes
           SET id_epis_report = NULL
         WHERE id_epis_report = ccur.id_epis_report;
      
        UPDATE alert_product_tr.presc_print
           SET id_epis_report = NULL
         WHERE id_epis_report = ccur.id_epis_report;
         
         UPDATE alert.epis_report e
           SET e.id_epis_parent = NULL
         WHERE e.id_epis_parent = ccur.id_epis_report;
      
        DELETE FROM epis_report WHERE ROWID = ccur.rowid;
      
        ncount := ncount + 1;
      
        IF ncount >= 10000 THEN
          COMMIT;
          ncount := 0;
        END IF;        
    END;
  END LOOP;

  COMMIT;
END;
/
-- CHANGE END: Pedro Henriques



-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 2017/05/18 09:55
-- CHANGE REASON: ALERT-330987

CREATE OR REPLACE PROCEDURE clean_old_epis_report IS

    -- Procedimento que elimina os registos temporarios na epis_report
    -- Realizado em concordância com o desenvolvimento 
    -- Executado a partir de um job diário

    CURSOR cepis_report IS
        SELECT er.id_epis_report
          FROM alert.epis_report er
         WHERE er.flg_status = 'N'
           AND er.flg_signed = 'N'
           AND NOT EXISTS (SELECT 1
                  FROM alert.ref_report rr
                 WHERE rr.id_epis_report = er.id_epis_report
                   AND rr.flg_type = 'D')
           AND NOT EXISTS (SELECT 1
                  FROM alert.epis_report erp
                 WHERE erp.id_epis_parent = er.id_epis_report)
           AND dt_creation_tstz < current_timestamp + numtodsinterval( -2, 'DAY')
				 ;

    TYPE cepis_type IS TABLE OF cepis_report%ROWTYPE;

    l_cepis_table cepis_type;

BEGIN

    OPEN cepis_report; 

    LOOP
        FETCH cepis_report BULK COLLECT
            INTO l_cepis_table LIMIT 1000;
    
        --------
        FORALL indx IN 1 .. l_cepis_table.count
            DELETE FROM epis_report_disclosure
             WHERE id_epis_report = l_cepis_table(indx).id_epis_report;
    
        FORALL indx IN 1 .. l_cepis_table.count
            DELETE FROM epis_report_section
             WHERE id_epis_report = l_cepis_table(indx).id_epis_report;
    
        FORALL indx IN 1 .. l_cepis_table.count
            DELETE FROM ref_report
             WHERE id_epis_report = l_cepis_table(indx).id_epis_report;
    
        FORALL indx IN 1 .. l_cepis_table.count
            UPDATE discharge_notes
               SET id_epis_report = NULL
             WHERE id_epis_report = l_cepis_table(indx).id_epis_report;
    
        FORALL indx IN 1 .. l_cepis_table.count
            UPDATE alert_product_tr.presc_print
               SET id_epis_report = NULL
             WHERE id_epis_report = l_cepis_table(indx).id_epis_report;
    
        FORALL indx IN 1 .. l_cepis_table.count
            UPDATE alert.epis_report e
               SET e.id_epis_parent = NULL
             WHERE e.id_epis_parent = l_cepis_table(indx).id_epis_report;
    
        FORALL indx IN 1 .. l_cepis_table.count
            DELETE FROM epis_report
             WHERE id_epis_report = l_cepis_table(indx).id_epis_report;
    
        COMMIT;
    
        EXIT WHEN l_cepis_table.count = 0;
    END LOOP;

    CLOSE cepis_report;

END;
/
-- CHANGE END: Pedro Henriques
