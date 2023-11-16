create or replace force view alert.v_cmt_set_general_map as
select "ALERT_SYSTEM","EXTERNAL_SYSTEM","ALERT_DEFINITION","EXTERNAL_DEFINITION","ALERT_VALUE","EXTERNAL_VALUE","ID_INSTITUTION","ID_SOFTWARE" from (
select a_system       ALERT_SYSTEM,
       b_system       EXTERNAL_SYSTEM,
       a_def          ALERT_DEFINITION,
       b_def          EXTERNAL_DEFINITION,
       a_value        ALERT_VALUE,
       b_value        EXTERNAL_VALUE,
       id_institution,
       id_software
  from inter_map.v_mapping a
 where a.a_system = sys_context('ALERT_CONTEXT', 'ALERT_SYSTEM')
   and a.a_def = sys_context('ALERT_CONTEXT', 'ALERT_DEFINITION')
   and a.a_value = sys_context('ALERT_CONTEXT', 'ALERT_VALUE')
   and a.b_system = sys_context('ALERT_CONTEXT', 'EXTERNAL_SYSTEM')
   and a.b_def = sys_context('ALERT_CONTEXT', 'EXTERNAL_DEFINITION')
   and a.id_institution in
       (sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'), 0)
   and a.id_software in (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0))
   order by id_institution desc,id_software desc, ALERT_VALUE;

