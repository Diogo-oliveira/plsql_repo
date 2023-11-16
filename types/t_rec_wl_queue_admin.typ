declare
	l_sql	varchar2(4000);
begin

	l_sql := q'[drop type t_tbl_wl_queue_admin]';
	pk_versioning.run(l_sql);
	
	l_sql := q'[drop type t_rec_wl_queue_admin]';
	pk_versioning.run(l_sql);
	

	l_sql := q'[
create or replace type t_rec_wl_queue_admin as object
    (
    id_wl_queue         number,
    inter_name_queue    varchar2(4000),
    char_queue        varchar2(4000),
    num_queue         number,
    flg_visible       varchar2(0010 char),
    flg_type_queue    varchar2(0100 char),
    flg_priority      varchar2(0100 char),
    foreground_color  varchar2(0100 char),
    color             varchar2(0100 char),
    code_msg            varchar2(4000),
    total_ahead         varchar2(4000),
    flg_allocated       varchar2(4000)
    )]';

	pk_versioning.run(l_sql);
	
	l_sql := q'[create or replace type t_tbl_wl_queue_admin as table of t_rec_wl_queue_admin]';

	pk_versioning.run(l_sql);
	
end;
/
