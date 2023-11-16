create or replace view v_adw_last_state_tracking as
select "ID_TRACKING","EXT_REQ_STATUS","DT_TRACKING","ID_EXTERNAL_REQUEST","ID_INSTITUTION","ID_PROFESSIONAL","FLG_TYPE","ID_PROF_DEST","ID_DEP_CLIN_SERV","ROUND_ID","REASON_CODE" 
 from p1_tracking 
 where (ID_EXTERNAL_REQUEST, ID_TRACKING) 
       in (select ID_EXTERNAL_REQUEST, max(ID_TRACKING) MAX_DT_TRACKING 
         from p1_tracking 
         group by ID_EXTERNAL_REQUEST, ROUND_ID)

