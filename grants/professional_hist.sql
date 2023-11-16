-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 06/07/2015 10:14
-- CHANGE REASON: [ALERT-313314] ALERT-313314 Issue Replication: The system must provide the ability to alert the users to update/confirm the bleep number when trying to add one medication order and display prescriber contact details in the prescription detail
grant select, references on PROFESSIONAL_HIST to ALERT_VIEWER, ALERT;
/
-- CHANGE END: Nuno Alves