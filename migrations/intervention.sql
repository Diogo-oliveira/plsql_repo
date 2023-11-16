-- CHANGED BY: Ana Matos
-- CHANGE DATE: 06/06/2018 12:00
-- CHANGE REASON: [EMR-3902] 
update intervention
set flg_category_type = 'P'
where flg_category_type is null;
-- CHANGE END: Ana Matos