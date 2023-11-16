create or replace view v_adw_read_tracking as
select "ID_TRACKING","EXT_REQ_STATUS","DT_TRACKING","ID_EXTERNAL_REQUEST","ID_INSTITUTION","ID_PROFESSIONAL","FLG_TYPE","ID_PROF_DEST","ID_DEP_CLIN_SERV","ROUND_ID","REASON_CODE" 
 from p1_tracking 
 where (ID_EXTERNAL_REQUEST, DT_TRACKING) 
       in (select ID_EXTERNAL_REQUEST, min(DT_TRACKING) MIN_DT_TRACKING 
         from p1_tracking 
		 where flg_type='R' 
         group by ID_EXTERNAL_REQUEST,EXT_REQ_STATUS,ROUND_ID)

