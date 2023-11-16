-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/03/2015 11:20
-- CHANGE REASON: [ALERT-308718] 
update exams_ea 
set notes_scheduler = notes;

update exams_ea  
set notes = null;
-- CHANGE END: Ana Matos