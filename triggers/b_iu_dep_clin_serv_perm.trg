CREATE OR REPLACE
TRIGGER "ALERT".B_IU_DEP_CLIN_SERV_PERM
 BEFORE INSERT OR UPDATE
 ON DEP_CLIN_SERV_PERM
 FOR EACH ROW
DECLARE-- PL/SQL Block
-- Declaration

    CURSOR DCSP_SEQ IS
        SELECT SEQ_DEP_CLIN_SERV_PERM.NEXTVAL
        FROM DUAL;
    WSEQ DEP_CLIN_SERV_PERM.ID_DEP_CLIN_SERV_PERM%TYPE;
BEGIN

    IF INSERTING THEN
        OPEN DCSP_SEQ;
        FETCH DCSP_SEQ INTO WSEQ;
        CLOSE DCSP_SEQ;
        -- Updates the Last Update Var
        :NEW.ADW_LAST_UPDATE := SYSDATE;

        :NEW.ID_DEP_CLIN_SERV_PERM := WSEQ;


    ELSIF UPDATING THEN

        -- Updates the Last Update Var
        :NEW.ADW_LAST_UPDATE := SYSDATE;

    END IF;
END;
/