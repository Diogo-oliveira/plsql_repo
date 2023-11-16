create or replace trigger A_IU_EPIS_PROF_RESP
  after insert or update of flg_status on epis_prof_resp  
  for each row
DECLARE
    -- local variables here
    status_order_completed CONSTANT VARCHAR2(1) := 'X';
    status_order_finalized CONSTANT VARCHAR2(1) := 'F';
BEGIN

    IF (inserting)
    THEN
        -- EPISODE_PROFESSIONAL_RESPONSABILITY_NEW      
        pk_ia_event_common.epis_prof_resp_new(i_id_epis_prof_resp => :NEW.id_epis_prof_resp,
                                              i_id_episode        => :NEW.id_episode);
    ELSIF (updating)
    THEN
        IF (:OLD.flg_status NOT IN (status_order_completed, status_order_finalized) AND
           :NEW.flg_status IN (status_order_completed, status_order_finalized))
        THEN
            -- EPISODE_PROFESSIONAL_RESPONSABILITY_COMPLETED       
            pk_ia_event_common.epis_prof_resp_completed(i_id_epis_prof_resp => :NEW.id_epis_prof_resp,
                                                        i_id_episode        => :NEW.id_episode);
        END IF;
    END IF;

END a_iu_epis_prof_resp;
/
