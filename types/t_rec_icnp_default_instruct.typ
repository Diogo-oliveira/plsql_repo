-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 04/02/2013
-- CHANGE REASON: [ALERT-250890]
DECLARE
    e_already_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_already_exists, -02303); -- cannot drop or replace a type with type or table dependents
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_icnp_default_instruct AS OBJECT
(
  id_composition  			NUMBER(24),
  id_order_recurr_option    NUMBER(24),
  id_order_recurr_plan		NUMBER(24),
  start_date				TIMESTAMP(6) WITH LOCAL TIME ZONE,
  flg_prn                   VARCHAR2(1 CHAR),
  prn_notes                 CLOB,
  flg_time                  VARCHAR2(1 CHAR)
)';
EXCEPTION
    WHEN e_already_exists THEN
        dbms_output.put_line('type t_rec_icnp_default_instruct already exists');
END;
/
-- CHANGE END: Tiago Silva