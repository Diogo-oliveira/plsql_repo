-- CHANGED BY: Ana Matos
-- CHANGE DATE: 19/09/2014 15:05
-- CHANGE REASON: [ALERT-296041] 
update exam_media_archive
set flg_status = 'A'
where flg_status is null;
-- CHANGE END: Ana Matos