-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 22/04/2015 16:03
-- CHANGE REASON: [ALERT-310274] The system must not allow other user than the prescriber to cancel or discontinue one order without co-sign
--                
GRANT EXECUTE, DEBUG ON t_table_co_sign TO ALERT_INTER WITH GRANT OPTION; 
-- CHANGE END: Elisabete Bugalho