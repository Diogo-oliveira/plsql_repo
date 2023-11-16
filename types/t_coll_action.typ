CREATE OR REPLACE TYPE t_coll_action AS TABLE OF t_rec_action
/

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 14/10/2010 16:40
-- CHANGE REASON: [ALERT-117147] 
create or replace type t_coll_action as table of t_rec_action;
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 04/11/2010 17:06
-- CHANGE REASON: [ALERT-137960] 
drop type t_coll_action;
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 04/11/2010 17:06
-- CHANGE REASON: [ALERT-137960] 
create or replace type t_coll_action as table of t_rec_action;
-- CHANGE END: Sérgio Santos