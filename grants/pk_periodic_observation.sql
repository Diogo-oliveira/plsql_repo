-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 26/08/2013 15:43
-- CHANGE REASON: [ALERT-263008] 
declare
  e_no_such_priv exception;
  pragma exception_init(e_no_such_priv, -01927);
begin
  execute immediate 'revoke execute on pk_periodic_observation from alert_viewer';
exception when e_no_such_priv then
  dbms_output.put_line('alert_viewer cannot execute pk_periodic_observation');
end;
/
-- CHANGE END: mario.mineiro