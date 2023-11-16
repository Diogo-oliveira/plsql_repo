-- CHANGED BY: Ana Matos
-- CHANGE DATE: 07/07/2014 11:14
-- CHANGE REASON: [ALERT-289548] 
update analysis_instit_recipient
set num_recipient = qty_harvest, qty_harvest = null
where num_recipient is null;
-- CHANGE END: Ana Matos