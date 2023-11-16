-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 08/03/2010 15:55
-- CHANGE REASON: [ALERT-73258] 
grant select on DIAG_DIAG_CONDITION to ALERT_VIEWER;
-- CHANGE END: Sérgio Santos


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-05-28
-- CHANGED REASON: EMR-777
grant select, insert, update, delete on DIAG_DIAG_CONDITION to ALERT_CORE_CNT with grant option;
-- CHANGE END: Humberto Cardoso
