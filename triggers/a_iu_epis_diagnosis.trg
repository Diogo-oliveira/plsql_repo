create or replace trigger A_IU_EPIS_DIAGNOSIS
  after insert or update on epis_diagnosis 
  for each row
DECLARE
    -- local variables here
    l_status_canceled CONSTANT VARCHAR2(1) := 'C';
		
    l_final_type_p CONSTANT VARCHAR2(1) := 'P';
    l_final_type_s CONSTANT VARCHAR2(1) := 'S';

BEGIN
    IF (inserting)
    THEN
        -- EPISODE_DIAGNOSIS_NEW
        pk_ia_event_common.epis_diagnosis_new(i_id_epis_diagnosis => :NEW.id_epis_diagnosis);

				
    ELSIF (updating)
    THEN
        -- EPISODE_DIAGNOSIS_CANCEL  
        IF (:OLD.flg_status <> l_status_canceled AND :NEW.flg_status = l_status_canceled)
        THEN
            pk_ia_event_common.epis_diagnosis_cancel(i_id_epis_diagnosis => :NEW.id_epis_diagnosis);
	ELSE
	    IF (nvl(:OLD.flg_final_type, l_final_type_s) <> l_final_type_p AND :NEW.flg_final_type = l_final_type_p)
	    THEN
		pk_ia_event_common.epis_diagnosis_change_type_pri(i_id_epis_diagnosis => :NEW.id_epis_diagnosis);
	    ELSIF (nvl(:OLD.flg_final_type, l_final_type_p) <> l_final_type_s AND :NEW.flg_final_type = l_final_type_s)
	    THEN
		pk_ia_event_common.epis_diagnosis_change_type_sec(i_id_epis_diagnosis => :NEW.id_epis_diagnosis);
	    ELSIF (:NEW.flg_final_type IS NULL)
	    THEN
		pk_ia_event_common.epis_diagnosis_change_type_non(i_id_epis_diagnosis => :NEW.id_epis_diagnosis);
            END IF;
        END IF;			
    END IF;
END A_IU_EPIS_DIAGNOSIS;
/
