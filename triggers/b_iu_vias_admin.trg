CREATE OR REPLACE
TRIGGER ALERT.B_IU_VIAS_ADMIN
BEFORE INSERT OR UPDATE
ON ALERT.INF_VIAS_ADMIN
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE

/******************************************************************************
   NAME:       B_IU_VIAS_ADMIN
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06-09-2006  Susana           1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     B_IU_VIAS_ADMIN
      Sysdate:         06-09-2006
      Date and Time:   06-09-2006, 8:24:01, and 06-09-2006 8:24:01
      Username:         (set in TOAD Options, Proc Templates)
      Table Name:      INF_VIAS_ADMIN (set in the "New PL/SQL Object" dialog)
      Trigger Options:  (set in the "New PL/SQL Object" dialog)
******************************************************************************/


BEGIN

IF :NEW.VIAS_ADMIN_ID IN (106,111,115) THEN
	:NEW.SHORT_DESCR := :NEW.DESCR;
ELSE
	:NEW.SHORT_DESCR := UPPER (SUBSTR ((SUBSTR (:NEW.descr, INSTR (RTRIM (:NEW.descr), ' ', -1) + 1)), 1, 1)) || SUBSTR ((SUBSTR (:NEW.descr, INSTR (RTRIM (:NEW.descr), ' ', -1) + 1)), 2);

END IF;

   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END B_IU_VIAS_ADMIN;
/
