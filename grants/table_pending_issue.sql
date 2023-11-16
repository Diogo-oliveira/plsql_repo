
CREATE OR REPLACE SYNONYM ALERT_VIEWER.pending_issue FOR pending_issue;

grant select on pending_issue to alert_viewer; 