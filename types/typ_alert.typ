CREATE OR REPLACE TYPE t_rec_alert AS OBJECT (
		 id_sys_alert_det				number
		,acuity							varchar2(0200 char)
		,date_send						varchar2(0050 char)
		,desc_epis_anamnesis			varchar2(4000)
		,desc_room						varchar2(0500 char)
		,dt_first_obs_tstz				TIMESTAMP(6) WITH LOCAL TIME ZONE
		,dt_req							varchar2(0050 char)
		,esi_level						varchar2(0200 char)
		,fast_track_color				varchar2(0200 char)
		,fast_track_icon				varchar2(0200 char)
		,fast_track_status				varchar2(0200 char)
		,flg_detail					varchar2(0001 char)
		,id_episode					number
		,gender							varchar2(0050 char)
		,id_institution				number
		,id_patient					number
		,id_prof						number
		,id_prof_order					number
		,id_reg							number
		,id_reg_det					number
		,id_room						number
		,id_schedule					number
		,id_software_origin			number
		,id_sys_alert					number
		,id_sys_shortcut				number
		,message						varchar2(4000)
		,name_pat						varchar2(0500 char)
		,name_pat_sort					varchar2(0500 char)
		,pat_age						varchar2(0050 char)
		,pat_ndo						varchar2(0500 char)
		,pat_nd_icon					varchar2(0500 char)
		,photo							varchar2(0500 char)
		,rank_acuity					number
		,resp_icons					varchar2(0300 char)
		,time							varchar2(0050 char)
		);

CREATE OR REPLACE TYPE t_tbl_alert AS TABLE OF t_rec_alert;
