-- CHANGED BY: Ana Matos
-- CHANGE DATE: 09/10/2013 10:18
-- CHANGE REASON: [ALERT-266574] 
UPDATE response r
   SET flg_free_text = 'N'
 WHERE flg_free_text IS NULL;
-- CHANGE END: Ana Matos