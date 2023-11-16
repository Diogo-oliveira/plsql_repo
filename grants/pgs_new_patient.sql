-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 28/03/2017 15:04
-- CHANGE REASON: [ALERT-329656]
BEGIN
    pk_versioning.run('GRANT SELECT ON ALERT.PGS_NEW_PATIENT TO ALERT_INTER WITH GRANT OPTION');
end;
/
-- CHANGE END: Pedro Henriques

-- CHANGED BY: Alexander Camilo
-- CHANGE DATE: 15/03/2018 09:23
-- CHANGE REASON: [EMR-481] NOM024 - View pgs_new_patient - give access to user alert_inter 
BEGIN
    pk_versioning.run('GRANT SELECT ON ALERT.PGS_NEW_PATIENT TO ALERT_INTER WITH GRANT OPTION');
end;
/
-- CHANGE END: Alexander Camilo