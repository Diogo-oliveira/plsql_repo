CREATE OR REPLACE
TRIGGER B_UD_UNIDOSE_CAR
 BEFORE DELETE OR UPDATE
 ON UNIDOSE_CAR
 FOR EACH ROW
-- PL/SQL Block
DECLARE

BEGIN

	INSERT INTO UNIDOSE_CAR_HIST
	(
		id_unidose_car,
		code_unidose_car,
		id_institution,
		adw_last_update,
		id_container_config,
		status,
		data_status_tstz,
		id_unidose_car_hist
	)
	VALUES
	(
		:old.id_unidose_car,
		:old.code_unidose_car,
		:old.id_institution,
		:old.adw_last_update,
		:old.id_container_config,
		:old.status,
		:old.data_status_tstz,
		seq_unidose_car_hist.nextval
	);

END;
/
