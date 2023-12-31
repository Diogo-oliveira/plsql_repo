DECLARE
BEGIN
    -- 1 - CREATE NEW COLUMN WITH VARCHAR2(200 CHAR) TYPE.
    EXECUTE IMMEDIATE 'ALTER TABLE PROFILE_CONTEXT ADD ID_CONTEXT_TMP VARCHAR2(200 CHAR)';

    -- 2 - COPY DATA FROM OLD COLUMN TO THE NEW ONE. CONVERTING DATA.
    EXECUTE IMMEDIATE 'UPDATE profile_context pc
                          SET pc.id_context_tmp = to_char(pc.id_context)';

    -- 3 - CHANGE OLD COLUMN TO ALLOW NULL VALUES
    EXECUTE IMMEDIATE 'ALTER TABLE PROFILE_CONTEXT MODIFY ID_CONTEXT NULL';

    -- 4 - CLEAN OLD COLUMN DATA.
    EXECUTE IMMEDIATE 'UPDATE profile_context pc
                          SET pc.id_context = NULL';

    -- 5 - ALTER OLD COLUMN TYPE TO VARCHAR2(200 CHAR).
    EXECUTE IMMEDIATE 'ALTER TABLE PROFILE_CONTEXT MODIFY ID_CONTEXT VARCHAR2(200 CHAR)';

    -- 6 - COPY DATA FROM THE NEW COLUMN TO THE OLD.
    EXECUTE IMMEDIATE 'UPDATE profile_context pc
                          SET pc.id_context = pc.id_context_tmp';

    -- 7 - DROP NEW COLUMN.
    EXECUTE IMMEDIATE 'ALTER TABLE PROFILE_CONTEXT DROP COLUMN ID_CONTEXT_TMP';

    -- 8 - CHANGE OLD COLUMN TO DON'T ALLOW NULL VALUES
    EXECUTE IMMEDIATE 'ALTER TABLE PROFILE_CONTEXT MODIFY ID_CONTEXT NOT NULL';
END;
/
