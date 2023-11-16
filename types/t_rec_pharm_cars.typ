create type t_rec_pharm_cars as object(
	id_drug_req_det		number(24),
	id_car_model		number(24),
	id_dep_clin_serv	number(24),
	car_name			varchar2(100 char)
);
