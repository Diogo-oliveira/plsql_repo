----
declare
	l_sql	varchar2(4000);
begin

	l_sql := q'[drop type t_tbl_wl_plasma]';
	pk_versioning.run(l_sql);
	
	l_sql := q'[drop type t_rec_wl_plasma]';
	pk_versioning.run(l_sql);
	

	l_sql := q'[
CREATE OR REPLACE TYPE t_rec_wl_plasma AS OBJECT (
	 message_audio			 varchar2(4000)
	,message_sound_file      varchar2(4000)
	,flg_type                varchar2(4000)
	,id_call_queue           number
	,color                   varchar2(4000)
	,char_queue              varchar2(4000)
	,number_queue            varchar2(4000)
	,desc_machine            varchar2(4000)
	,triage_color            varchar2(4000)
	,triage_color_text       varchar2(4000)
	,titulo                  varchar2(4000)
	,label_name              varchar2(4000)
	,label_room              varchar2(4000)
	,nome                    varchar2(4000)
	,url_photo               varchar2(4000)
)]';

	pk_versioning.run(l_sql);
	
	l_sql := q'[CREATE OR REPLACE TYPE t_tbl_wl_plasma AS TABLE OF t_rec_wl_plasma]';

	pk_versioning.run(l_sql);
	
end;
/
