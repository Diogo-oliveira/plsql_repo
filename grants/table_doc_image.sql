

  GRANT ALTER ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT DELETE ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT INDEX ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT INSERT ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT SELECT ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT UPDATE ON ALERT.DOC_IMAGE TO ALERT_VIEWER;


  GRANT REFERENCES ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT ON COMMIT REFRESH ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT QUERY REWRITE ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT DEBUG ON ALERT.DOC_IMAGE TO ALERT_VIEWER;

  GRANT FLASHBACK ON ALERT.DOC_IMAGE TO ALERT_VIEWER;




-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 08/03/2010 14:06
-- CHANGE REASON: [ALERT-79864] 
grant select on doc_image to interface_p1;
-- CHANGE END: Ana Monteiro