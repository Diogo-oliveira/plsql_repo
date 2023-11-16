-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2013-02-20
-- CHANGE REASON: ADT-7364

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -01418);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE contact_object AS OBJECT(
  id_contact_address        NUMBER(24),
  id_country                NUMBER(24),
  address_line1             VARCHAR2(200 CHAR),
  regional_entity           VARCHAR2(30 CHAR),
  location                  VARCHAR2(200 CHAR),
  postal_code               VARCHAR2(100 CHAR),
  address_line2             VARCHAR2(200 CHAR),
  address_line3             VARCHAR2(200 CHAR),
  flg_main_address          VARCHAR2(1 CHAR),
  door_number               VARCHAR2(100 CHAR),
  floor                     VARCHAR2(30 CHAR),
  floor_home                VARCHAR2(30 CHAR),
  institution_key           NUMBER(24),
  geo_ref_latitude          VARCHAR2(30 CHAR),
  geo_ref_longitude         VARCHAR2(30 CHAR),
  record_status             VARCHAR2(1 CHAR),
  import_code               VARCHAR2(30 CHAR),
  flg_address_type          VARCHAR2(1 CHAR),
  flg_street_type           VARCHAR2(1 CHAR),
  id_rb_regional_classifier NUMBER(24),
  position                      NUMBER(24),
  relevance                     NUMBER(24, 10))';
    EXCEPTION
        WHEN e_object_exists THEN
            dbms_output.put_line('AVISO: Operacao ja executada anteriormente.');
    END;

END;
/

-- CHANGED END: Bruno Martins

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2013-02-20
-- CHANGE REASON: ADT-7364

DECLARE
    e_object_exists EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_object_exists, -01418);
BEGIN

    BEGIN
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE contact_table_type AS TABLE OF contact_object';
    EXCEPTION
        WHEN e_object_exists THEN
            dbms_output.put_line('AVISO: Operacao ja executada anteriormente.');
    END;

END;
/

-- CHANGED END: Bruno Martins