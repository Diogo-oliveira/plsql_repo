create or replace view v_adw_first_tracking as
select "ID_TRACKING","EXT_REQ_STATUS","DT_TRACKING","ID_EXTERNAL_REQUEST","ID_INSTITUTION","ID_PROFESSIONAL","FLG_TYPE","ID_PROF_DEST","ID_DEP_CLIN_SERV","ROUND_ID","REASON_CODE" 
 from p1_tracking 
 where (ID_EXTERNAL_REQUEST, ROUND_ID) 
       in (select ID_EXTERNAL_REQUEST, min(ROUND_ID) 
         from p1_tracking 
		 where ROUND_ID is not null 
         group by ID_EXTERNAL_REQUEST)

