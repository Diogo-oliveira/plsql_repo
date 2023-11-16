create or replace view v_prof_msg_inbox as
SELECT t.*
  FROM TABLE(pk_backoffice_pending_issues.get_professional_inbox(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 sys_context('ALERT_CONTEXT', 'i_id_prof'))) t;

