CREATE OR REPLACE
TRIGGER
B_IU_PATPHOTO_RESET
    BEFORE UPDATE ON PAT_PHOTO_OLD
BEGIN
    pk_patphoto.updrows := pk_patphoto.emptyupdrows;
END;

/
