CREATE OR REPLACE TYPE "ACSS_PRICES" AS OBJECT
(
  EMB_ID VARCHAR2(255),
  PRECO_SNS NUMBER(24,6),
  PRECO_UTENTE NUMBER(24,6),
  COMPART VARCHAR2(255)
);