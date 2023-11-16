-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant execute on PK_PROF_UTILS to ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 14:42
-- CHANGE REASON: [ALERT-206805] 
GRANT EXECUTE ON PK_PROF_UTILS TO ALERT_PRODUCT_MT;
-- CHANGE END: Pedro Quinteiro

GRANT EXECUTE ON PK_PROF_UTILS TO ALERT_CORE_TECH;

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2013-12-06
-- CHANGE REASON: ALERT-271022

grant execute on PK_PROF_UTILS to alert_adtcod;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 09:43
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
grant execute on pk_prof_utils to alert_pharmacy_func;
-- CHANGE END: Alexis Nascimento

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 04/09/2015 12:10
-- CHANGE REASON: [ADW-6762 ] grants to user adw_stg - report farmacêutico AHP
GRANT EXECUTE ON alert.pk_prof_utils TO adw_stg; 
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/09/2015 09:05
-- CHANGE REASON: [ADW-6762 ] grants to user adw_stg - report farmacêutico AHP
GRANT EXECUTE ON alert.pk_prof_utils TO adw_stg; 
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 14/02/2017 17:27
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('grant execute on PK_PROF_UTILS to ALERT_PRODUCT_TR with grant option');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/03/2017 15:04
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('grant execute on PK_PROF_UTILS to ALERT_PRODUCT_TR with grant option');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 02/08/2020 15:04
-- CHANGE REASON: [EMR-34709] 
BEGIN
    pk_versioning.run('grant execute on PK_PROF_UTILS to ALERT_PDMS_TR with grant option');
END;
/
-- CHANGE END: Pedro Henriques

-- CHANGED BY: Nuno Amorim
-- CHANGE DATE: 30/11/2020 11:00
-- CHANGE REASON: [EMR-38804] Videoconference: physician's name is precedeed by the prefixe
BEGIN
    pk_versioning.run('grant execute on PK_PROF_UTILS to ALERT_APSSCHDLR_TR with grant option';
END;
/
-- CHANGE END: Nuno Amorim