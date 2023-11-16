-- CHANGED BY: Rui Duarte
-- CHANGE DATE: 22/11/2010 15:26
-- CHANGE REASON: [ALERT-143418] PK_REPORTS issue replication
DECLARE
    l_table_name VARCHAR2(30) := 'rep_scope_inst_soft_market';
BEGIN
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || l_table_name || ' TO alert_viewer';
END;
/

GRANT EXECUTE ON ALERT.PK_REPORTS TO ALERT_VIEWER;
-- CHANGE END: Rui Duarte