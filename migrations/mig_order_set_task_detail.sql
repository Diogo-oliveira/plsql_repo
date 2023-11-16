-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 02/03/2012
-- CHANGE REASON: [ALERT-220948]
-- value correction of "authorization for use of generics" medication field
UPDATE order_set_task_detail
   SET vvalue = 'Y'
 WHERE flg_detail_type = 'G'
   AND length(vvalue) > 1;
-- CHANGE END: Tiago Silva
