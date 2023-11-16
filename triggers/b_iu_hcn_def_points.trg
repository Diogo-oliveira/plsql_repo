CREATE OR REPLACE TRIGGER B_IU_HCN_DEF_POINTS
 BEFORE INSERT OR UPDATE
 ON HCN_DEF_POINTS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin
    
   :new.adw_last_update := sysdate; 
end;
/	