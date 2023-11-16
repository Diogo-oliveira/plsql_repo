
create type t_rec_pharm_uni_car_drawer as object
(
	id_unidose_car	number(24),
	drawer_number	number(3),
	car_model_name	varchar2(100),
	drawer_label	varchar2(100)
);
/
