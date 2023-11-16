-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE: 18/07/2013
-- CHANGE REASON: ALERT-217073

DECLARE
  l_table_name VARCHAR2(30) := 'REP_EDITABLE_TEXT_INST_SOFT';
BEGIN
  EXECUTE IMMEDIATE 'GRANT SELECT ON ' || l_table_name ||
                    ' TO alert_viewer';
END;
/

-- CHANGE END: filipe.f.pereira