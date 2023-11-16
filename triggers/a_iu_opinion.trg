CREATE OR REPLACE TRIGGER a_iu_opinion
    AFTER INSERT OR UPDATE OF flg_state ON opinion
    FOR EACH ROW
DECLARE

    -- local variables here
    status_order_replied CONSTANT VARCHAR2(1) := 'P';
BEGIN

    IF (updating)
    THEN
        IF (:OLD.flg_state <> status_order_replied AND :NEW.flg_state = status_order_replied)
        THEN
            -- OPINION_ORDER_READ       
            pk_ia_event_common.opinion_order_replied(i_id_opinion => :NEW.id_opinion, i_id_episode => :NEW.id_episode);
        END IF;
    END IF;
END a_iu_opinion;
