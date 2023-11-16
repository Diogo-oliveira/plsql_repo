create or replace type t_rec_related_med as object
(
  med_id varchar2(255),
	med_descr varchar2(4000),
	flg_default varchar2(1)
);