CREATE OR REPLACE TRIGGER a_iu_episode
    AFTER INSERT OR UPDATE ON episode
    FOR EACH ROW
DECLARE
    -- local variables here
    status_canceled CONSTANT VARCHAR2(1) := 'C';

    flg_ehr_normal    CONSTANT VARCHAR2(1) := 'N';
    flg_ehr_scheduled CONSTANT VARCHAR2(1) := 'S';
    inp_epis          CONSTANT PLS_INTEGER := 5;
    oris_epis         CONSTANT PLS_INTEGER := 4;
BEGIN
    IF (inserting)
    THEN
        IF ((:NEW.id_epis_type NOT IN (inp_epis, oris_epis)) OR
           (:NEW.id_epis_type = inp_epis AND :NEW.flg_ehr = flg_ehr_normal) OR
           (:NEW.id_epis_type = oris_epis AND :NEW.flg_ehr = flg_ehr_normal))
        THEN
            -- EPISODE_NEW
            pk_ia_event_common.episode_new(i_id_institution => :NEW.id_institution, i_id_episode => :NEW.id_episode);
        END IF;
        IF pk_patient.ckeck_has_process_number(:new.id_patient, :new.id_institution) = pk_alert_constant.g_no
        THEN
            pk_ia_event_common.institution_first_episode_new(i_id_institution => :new.id_institution,
                                                             i_id_episode     => :new.id_episode);
        END IF;
    ELSIF (updating)
    THEN
        --
        IF (:OLD.flg_ehr <> :NEW.flg_ehr AND :NEW.flg_ehr = flg_ehr_normal AND :OLD.flg_ehr = flg_ehr_scheduled AND
           :NEW.id_epis_type IN (inp_epis, oris_epis))
        THEN
            pk_ia_event_common.episode_new(i_id_institution => :NEW.id_institution, i_id_episode => :NEW.id_episode);
        ELSIF (:OLD.flg_ehr <> :NEW.flg_ehr AND :NEW.flg_ehr = flg_ehr_scheduled AND :OLD.flg_ehr = flg_ehr_normal AND
              :NEW.id_epis_type IN (inp_epis, oris_epis))
        THEN
            -- EPISODE_CANCEL
            pk_ia_event_common.episode_cancel(i_id_institution => :NEW.id_institution, i_id_episode => :NEW.id_episode);
        END IF;
    
        IF (:OLD.flg_status <> status_canceled AND :NEW.flg_status = status_canceled)
        THEN
            -- EPISODE_CANCEL
            pk_ia_event_common.episode_cancel(i_id_institution => :NEW.id_institution, i_id_episode => :NEW.id_episode);
        ELSIF (:OLD.flg_ehr <> :NEW.flg_ehr AND :NEW.flg_status = flg_ehr_normal AND
              :OLD.flg_status = flg_ehr_scheduled)
        THEN
            -- CHANGE_EPISODE_FLG_EHR_NORMAL 
            pk_ia_event_common.change_episode_flg_ehr_normal(i_id_institution => :NEW.id_institution,
                                                             i_id_episode     => :NEW.id_episode);
        END IF;
    END IF;
END a_iu_episode;
/
