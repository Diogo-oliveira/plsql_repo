CREATE OR REPLACE TRIGGER B_IU_EQUIP_PROTOCOLS
 BEFORE INSERT OR UPDATE OF ID_SR_EQUIP, ID_PROTOCOLS, ID_EQUIP_PROTOCOLS
 ON EQUIP_PROTOCOLS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
BEGIN
:new.adw_last_update := sysdate;
END;
/