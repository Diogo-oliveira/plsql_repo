GRANT EXECUTE ON ALERT.PK_VISIT TO ALERT_INTER;


-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2018-2-2
-- CHANGED REASON: EMR-822

BEGIN
    pk_versioning.run('grant execute on pk_visit to ALERT_PHARMACY_FUNC with grant option');
END;
/
-- CHANGE END: Joao Coutinho
