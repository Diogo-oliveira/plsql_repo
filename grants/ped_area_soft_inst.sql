-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 26/07/2011 15:01
-- CHANGE REASON: [ALERT-188174] 
GRANT SELECT ON ped_area_soft_inst TO alert_viewer;
GRANT ALTER,DEBUG,DELETE,FLASHBACK,INDEX,INSERT,ON COMMIT REFRESH,QUERY REWRITE,REFERENCES,SELECT,UPDATE ON ped_area_soft_inst TO inter_alert_v2;
-- CHANGE END: Paulo Teixeira

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select,insert,update,delete on ped_area_soft_inst to alert_apex_tools;
-- CHANGE END:  luis.r.silva