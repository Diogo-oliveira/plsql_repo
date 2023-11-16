-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
grant select on v_sch_cancel_reason_inst to intf_alert;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 19/11/2010 17:03
-- CHANGE REASON: [ALERT-143110] 
grant select on v_sch_cancel_reason_inst to alert_apsschdlr_tr;
-- CHANGE END: Sérgio Santos