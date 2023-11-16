
create type t_rec_pharm_drd_allocation as object
(
	id_unidose_car	number(24),
	car_model_name	varchar2(100 char),
	slot_number		number(3),
	slot_name		varchar2(500 char)
);
/
