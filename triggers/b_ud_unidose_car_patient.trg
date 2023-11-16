CREATE OR REPLACE
TRIGGER B_UD_UNIDOSE_CAR_PATIENT
 BEFORE DELETE OR UPDATE
 ON UNIDOSE_CAR_PATIENT
 FOR EACH ROW
-- PL/SQL Block
DECLARE

BEGIN

    INSERT INTO unidose_car_patient_hist
        (id_unidose_car_patient_hist,
         id_unidose_car,
         id_institution,
         id_patient,
         id_container,
         id_unidose_car_route,
         flg_available,
         adw_date,
         bar_code,
		 id_episode,
		 id_unidose_car_patient_history)
    VALUES
        (:OLD.id_unidose_car_patient,
         :OLD.id_unidose_car,
         :OLD.id_institution,
         :OLD.id_patient,
         :OLD.id_container,
         :OLD.id_unidose_car_route,
         :OLD.flg_available,
         :OLD.adw_date,
         :OLD.bar_code,
		 :OLD.id_episode,
		 seq_unidose_car_patient_hist.nextval);

END;
/
