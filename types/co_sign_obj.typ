CREATE OR REPLACE TYPE "CO_SIGN_OBJ"                                                                          AS OBJECT
(
   DT_ORDER           TIMESTAMP(6) WITH LOCAL TIME ZONE,
	  ID_PROF_ORDER        NUMBER(24),
  ID_ORDER_TYPE        NUMBER(24),
	 FLG_CO_SIGN          VARCHAR2(1) ,
  DT_CO_SIGN           TIMESTAMP(6) WITH LOCAL TIME ZONE,
  NOTES_CO_SIGN        VARCHAR2(4000),
  ID_PROF_CO_SIGN      NUMBER(24)
);

/
