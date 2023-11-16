create or replace view v_supply_requests as
SELECT t.*,
       sys_context('ALERT_CONTEXT', 'l_lang') l_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') l_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') l_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') l_prof_software
  FROM TABLE(pk_supplies_core.tf_get_supply_requests(i_lang => sys_context('ALERT_CONTEXT', 'l_lang'),
                                                     i_prof => profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),
                                                                            sys_context('ALERT_CONTEXT',
                                                                                        'l_prof_institution'),
                                                                            sys_context('ALERT_CONTEXT', 'l_prof_software')))) t;
