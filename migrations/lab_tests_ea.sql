-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/03/2015 11:20
-- CHANGE REASON: [ALERT-308718] 
update lab_tests_ea 
set notes_scheduler = notes;

update lab_tests_ea 
set notes = null;
-- CHANGE END: Ana Matos