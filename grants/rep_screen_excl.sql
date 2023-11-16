-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 21-Jan-2011
-- CHANGE REASON: ALERT-156863
DECLARE
    l_table_name VARCHAR2(30) := 'rep_screen_excl';
BEGIN
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || l_table_name || ' TO alert_viewer';
END;
/

GRANT EXECUTE ON ALERT.PK_REPORTS TO ALERT_VIEWER;
-- CHANGE END
