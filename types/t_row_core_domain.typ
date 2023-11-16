drop type t_tbl_core_Domain;
drop type t_row_core_Domain;


create or replace type t_row_core_domain as object
	(

	internal_name	varchar2(0200 char),
	desc_domain		varchar2(4000),
	domain_value    varchar2(1000 char),
	order_rank		number,
	img_name        varchar2(1000 char)
    )
;

create or replace type t_tbl_core_Domain as table of t_row_core_domain;


