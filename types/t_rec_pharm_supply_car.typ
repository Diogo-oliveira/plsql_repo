create type t_rec_pharm_supply_car as object(
	id_drug				varchar2(255 char),
	version				varchar2(10 char),
	id_unit_disp		number(24),
	qty_disp			number(24,4),
	lot_number			varchar2(100 char),
	dt_expire			varchar2(50 char),
	id_drug_req_supply	number(24),
	id_drug_presc_det	number(24),
	id_other_product	number(24),
	id_dep_clin_serv	number(12),
	id_car_model		number(24),
	car_name			varchar2(50 char)
);
