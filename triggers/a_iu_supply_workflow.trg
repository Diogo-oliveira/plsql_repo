-- CHANGED BY: Daniel Grosso
-- CHANGE DATE: 2010-06-04
-- CHANGE REASON: ALERT-102262

CREATE OR REPLACE TRIGGER "A_IU_SUPPLY_WORKFLOW"
    AFTER INSERT OR UPDATE OF quantity OR UPDATE OF flg_status ON supply_workflow
    FOR EACH ROW
BEGIN
    IF (inserting)
    THEN
        -- SUPPLY_WORKFLOW_NEW
        pk_ia_event_common.supply_workflow_new(i_id_supply_workflow => :NEW.id_supply_workflow);
    ELSIF (updating)
    THEN
    
        IF (:OLD.quantity <> :NEW.quantity)
        THEN
            -- SUPPLY_WORKFLOW_CHANGE_QUANTITY
            pk_ia_event_common.supply_wf_change_quantity(i_id_supply_workflow => :NEW.id_supply_workflow);
        END IF;
        IF (:OLD.flg_status <> :NEW.flg_status)
        THEN
            -- SUPPLY_WORKFLOW_CHANGE_STATUS
            pk_ia_event_common.supply_wf_change_status(i_id_supply_workflow => :NEW.id_supply_workflow);
        END IF;
    
    END IF;
END a_iu_supply_workflow;

-- CHANGE END
/

-- CHANGED BY: Teresa Coutinho
-- CHANGE DATE: 2012-04-04
-- CHANGE REASON: ALERT-226633  
drop trigger A_IU_SUPPLY_WORKFLOW;