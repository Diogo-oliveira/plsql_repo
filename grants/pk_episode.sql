-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 15/07/2009
-- CHANGE REASON: ALERT-36064
grant execute on pk_episode to alert_adtcod;
-- CHANGE END: Bruno Martins

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 29-APR-2011
-- CHANGE REASON: [ALERT-175361] 
grant execute on pk_episode to alert_reset;
-- CHANGE END

-- CHANGED BY: hugo.madureira
-- CHANGE DATE: 2014-11-05
-- CHANGE REASON: CODING-2564
grant execute on ALERT.PK_EPISODE to ALERT_INTER with grant option;
-- CHANGE END: hugo.madureira


-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 07/01/2015 08:38
-- CHANGE REASON: [ALERT-305426] ALERT_302969 - PK_CORE_CONFIG.TF_CONFIG
GRANT EXECUTE ON PK_EPISODE TO ALERT_CORE_TECH; 
-- CHANGE END: Alexandre Santos

--ALERT-303139 (begin) vitor.reis
--ALERT
GRANT EXECUTE ON PK_EPISODE TO ALERT_PRODUCT_TR; 
--ALERT-303139 (end) vitor.reis

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 14/02/2017 17:27
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT EXECUTE ON PK_EPISODE TO ALERT_PRODUCT_TR with grant option');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/03/2017 15:04
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('GRANT EXECUTE ON PK_EPISODE TO ALERT_PRODUCT_TR with grant option');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 14/12/2016 16:43
-- CHANGE REASON: [ALERT_326080] Viewer checklists revision code
BEGIN
    pk_versioning.run('GRANT EXECUTE ON pk_episode TO alert_pharmacy_func');
END;
/

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/09/2018 10:24
-- CHANGE REASON: [EMR-7067] 
BEGIN
    pk_versioning.run('GRANT EXECUTE ON PK_EPISODE TO ALERT_PRODUCT_MT with grant option');
END;
/
-- CHANGE END: Sofia Mendes