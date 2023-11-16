CREATE OR REPLACE TRIGGER A_IU_EPIS_SUPPLIES_DET
  AFTER INSERT OR UPDATE OF QTY ON EPIS_SUPPLIES_DET  
  FOR EACH ROW
BEGIN
    IF (inserting) THEN
        -- SUPPLY_NEW
        pk_ia_event_common.supply_new(i_id_epis_supplies_det => :NEW.id_epis_supplies_det);
    ELSIF (updating) AND :OLD.qty <> :NEW.qty THEN
            -- SUPPLY_CHANGE_QUANTITY
            pk_ia_event_common.supply_change_quantity(i_id_epis_supplies_det => :NEW.id_epis_supplies_det);
    END IF;
END A_IU_EPIS_SUPPLIES_DET;
/
