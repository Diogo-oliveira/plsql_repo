CREATE OR REPLACE TRIGGER B_U_PAT_REFERRAL
   BEFORE UPDATE OF id_schedule
   ON ALERT.PAT_REFERRAL
   FOR EACH ROW
DECLARE
   l_error                  VARCHAR2 (4000);
   l_ret                    BOOLEAN;
   my_exception             exception;

   l_prof                   ALERT.PROFISSIONAL;

   l_obj_name               VARCHAR2(32);

   l_reshedule              varchar2(1);
   l_inst                   institution.id_institution%type;
   l_date                   date;
   l_date_tstz              timestamp;
   l_cancel_reason          varchar2(4000);

BEGIN

   -- Log initialization.
   l_obj_name := pk_alertlog.who_am_i;
   pk_alertlog.log_init(l_obj_name);

   -- Agendamento/Reagendamento
   if :new.id_schedule is not null then

     -- Obter data e instituição
     select id_instit_requests, dt_begin, dt_begin_tstz into l_inst, l_date, l_date_tstz from schedule where id_schedule = :new.id_schedule;

     l_prof := ALERT.PROFISSIONAL(pk_sysconfig.get_config('P1_INTERFACE_PROF_ID',l_inst,to_number(pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)))),
                                  l_inst,
                                  pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)));

     -- É reagendamento
     if :old.id_schedule is not null
     then l_reshedule := 'Y';
     else l_reshedule := 'N';
     end if;

     -- Call setstatusscheduled
     l_ret := alert.pk_p1_interface.set_status_scheduled(1, l_prof, :new.ref_num, :new.id_schedule, :new.id_dep_clin_serv, l_date, pk_date_utils.date_send_tsz(1, l_date_tstz, l_prof), l_reshedule, l_error);

     if not l_ret then
        raise my_exception;
     end if;
   -- Cancelar agendamento
   else

     -- Obter data e instituição
     select id_instit_requests,
            pk_message.get_message(1, 'P1_EXT_SYS_M001') || ': ' ||pk_translation.get_translation(1, scr.code_cancel_reason)
     into l_inst, l_cancel_reason
     from schedule s, sch_cancel_reason scr
     where s.id_schedule = :old.id_schedule
           and s.id_cancel_reason = scr.id_sch_cancel_reason;

     l_prof := ALERT.PROFISSIONAL(pk_sysconfig.get_config('P1_INTERFACE_PROF_ID',l_inst,to_number(pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)))),
                                  l_inst,
                                  pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)));

     -- Call setstatusscheduled
     l_ret := alert.pk_p1_interface.set_status_cancel(1, l_prof, :new.ref_num, l_cancel_reason, l_error);

     if not l_ret then
        raise my_exception;
     end if;

   end if;
EXCEPTION
   WHEN OTHERS
   THEN
   alertlog.pk_alertlog.log_error(l_error);
END;
/


-- pk_p1_interface.set_status_scheduled tem novo parametro: l_prof_sch
CREATE OR REPLACE TRIGGER B_U_PAT_REFERRAL
   BEFORE UPDATE OF id_schedule
   ON ALERT.PAT_REFERRAL
   FOR EACH ROW
DECLARE
   l_error                  VARCHAR2 (4000);
   l_ret                    BOOLEAN;
   my_exception             exception;

   l_prof                   ALERT.PROFISSIONAL;

   l_obj_name               VARCHAR2(32);

   l_reshedule              varchar2(1);
   l_inst                   institution.id_institution%type;
   l_date                   date;
   l_date_tstz              timestamp;
   l_prof_sch                professional.id_professional%type;
   l_cancel_reason          varchar2(4000);

BEGIN

   -- Log initialization.
   l_obj_name := pk_alertlog.who_am_i;
   pk_alertlog.log_init(l_obj_name);

   -- Agendamento/Reagendamento
   if :new.id_schedule is not null then

     -- Obter data e instituição
     select s.id_instit_requests, s.dt_begin, s.dt_begin_tstz, spo.id_professional into l_inst, l_date, l_date_tstz, l_prof_sch
     from schedule s, schedule_outp so, sch_prof_outp spo
     where s.id_schedule = :new.id_schedule
           and s.id_schedule = so.id_schedule(+)
           and so.id_schedule_outp = spo.id_schedule_outp(+);

     l_prof := ALERT.PROFISSIONAL(pk_sysconfig.get_config('P1_INTERFACE_PROF_ID',l_inst,to_number(pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)))),
                                  l_inst,
                                  pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)));

     -- É reagendamento
     if :old.id_schedule is not null
     then l_reshedule := 'Y';
     else l_reshedule := 'N';
     end if;

     -- Call setstatusscheduled
     l_ret := alert.pk_p1_interface.set_status_scheduled(1, l_prof, :new.ref_num, :new.id_schedule, :new.id_dep_clin_serv, l_date, pk_date_utils.date_send_tsz(1, l_date_tstz, l_prof), l_prof_sch, l_reshedule, l_error);

     if not l_ret then
        raise my_exception;
     end if;
   -- Cancelar agendamento
   else

     -- Obter data e instituição
     select id_instit_requests,
            pk_message.get_message(1, 'P1_EXT_SYS_M001') || ': ' ||pk_translation.get_translation(1, scr.code_cancel_reason)
     into l_inst, l_cancel_reason
     from schedule s, sch_cancel_reason scr
     where s.id_schedule = :old.id_schedule
           and s.id_cancel_reason = scr.id_sch_cancel_reason;

     l_prof := ALERT.PROFISSIONAL(pk_sysconfig.get_config('P1_INTERFACE_PROF_ID',l_inst,to_number(pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)))),
                                  l_inst,
                                  pk_sysconfig.GET_CONFIG('SOFTWARE_ID_P1', ALERT.PROFISSIONAL(NULL, NULL, NULL)));

     -- Call setstatusscheduled
     l_ret := alert.pk_p1_interface.set_status_cancel(1, l_prof, :new.ref_num, l_cancel_reason, l_error);

     if not l_ret then
        raise my_exception;
     end if;

   end if;
EXCEPTION
   WHEN OTHERS
   THEN
   alertlog.pk_alertlog.log_error(l_error);
END;
/

-- [2.4.3] Deixa de ser usada a pat_referral
drop trigger B_U_PAT_REFERRAL;
/