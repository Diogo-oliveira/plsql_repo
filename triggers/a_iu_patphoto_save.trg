CREATE OR REPLACE
TRIGGER
A_IU_PATPHOTO_SAVE
   AFTER UPDATE ON PAT_PHOTO_OLD FOR EACH ROW
BEGIN
     Pk_Patphoto.updRows( Pk_Patphoto.updRows.COUNT+1 ) := :OLD.ID_PAT_PHOTO;
  END;

/
