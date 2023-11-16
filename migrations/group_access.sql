-- CHANGED BY: Ana Matos
-- CHANGE DATE: 13/02/2017 13:51
-- CHANGE REASON: [ALERT-328796] 
update group_access
set id_software = 0
where id_software is null;
-- CHANGE END: Ana Matos