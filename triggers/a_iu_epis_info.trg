CREATE OR REPLACE TRIGGER a_iu_epis_info
    AFTER INSERT OR UPDATE ON epis_info
    FOR EACH ROW
DECLARE
    -- local variables here
    status_canceled CONSTANT VARCHAR2(1) := 'C';

    flg_ehr_normal    CONSTANT VARCHAR2(1) := 'N';
    flg_ehr_scheduled CONSTANT VARCHAR2(1) := 'S';

BEGIN
    IF (updating)
    THEN
        IF ((:OLD.id_room <> :NEW.id_room AND :NEW.id_room IS NOT NULL AND :OLD.id_room IS NOT NULL) OR
           (:OLD.id_bed <> :NEW.id_bed AND :NEW.id_bed IS NOT NULL AND :OLD.id_bed IS NOT NULL))
        THEN
            -- CHANGE_ASSIGNED_PATIONT_LOCATION
            pk_ia_event_common.change_assigned_pat_location(i_id_episode => :NEW.id_episode);
        END IF;
    END IF;
END a_iu_episode;
/
