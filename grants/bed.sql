-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.BED to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2018-2-2
-- CHANGED REASON: EMR-822

BEGIN
    pk_versioning.run('grant select on alert.room to alert_product_tr');
END;
/
-- CHANGE END: Joao Coutinho

-- CHANGED BY: André Silva
-- CHANGE DATE: 20/03/2018
-- CHANGE REASON: EMR-2096
GRANT SELECT ON BED TO ALERT_INTER;
-- CHANGED END: André Silva