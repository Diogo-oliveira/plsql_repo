-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 14/12/2016 16:43
-- CHANGE REASON: [ALERT_326080] Viewer checklists revision code
BEGIN
    pk_versioning.run('GRANT SELECT ON patient TO alert_pharmacy_func');
END;
/
-- CHANGE END: rui.mendonca