
create or replace type t_rec_pharm_vision
as object
(
	id_action number(24),
	id_parent number(24),
	desc_action varchar2(4000 char),
	icon varchar2(200 char),
	flg_status varchar2(1 char),
	rank number(4),
	xinfo varchar2(200 char)
);
/
/
