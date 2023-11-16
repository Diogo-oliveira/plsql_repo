-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2010-04-08
-- CHANGE REASON: ALERT-87417

grant execute on pk_patphoto to alert_adtcod;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 27/06/2014 16:53
-- CHANGE REASON: [ALERT-288807] RESET new application
grant execute on pk_patphoto to alert_reset;
-- CHANGE END: Gustavo Serrano


-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2018-2-2
-- CHANGED REASON: EMR-822

BEGIN
    pk_versioning.run('grant execute on pk_patphoto to ALERT_PHARMACY_FUNC with grant option');
END;
/
-- CHANGE END: Joao Coutinho
