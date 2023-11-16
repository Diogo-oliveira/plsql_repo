CREATE OR REPLACE TRIGGER a_i_spo_vacancies
   AFTER INSERT
   ON alert.SCH_PROF_OUTP
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
   l_schedule        SCHEDULE%ROWTYPE;
   l_schedule_outp   SCHEDULE_OUTP%ROWTYPE;
   l_sqlerrm         VARCHAR2 (4000);
/******************************************************************************
   NAME:       A_I_SPO_VACANCIES
   PURPOSE:    Refresh vacancies after a consultation insertion

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        20-09-2006  Ricardo Pinho    1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     A_I_SPO_VACANCIES
      Sysdate:         20-09-2006
      Date and Time:   20-09-2006, 22:32:15, and 20-09-2006 22:32:15
******************************************************************************/
BEGIN
   SELECT so.*
     INTO l_schedule_outp
     FROM SCHEDULE_OUTP so
    WHERE so.id_schedule_outp = :NEW.id_schedule_outp;

   SELECT s.*
     INTO l_schedule
     FROM SCHEDULE s
    WHERE s.id_schedule = l_schedule_outp.id_schedule;

   IF l_schedule_outp.flg_vacancy != 'V' THEN
      /* if it's not an overbooking appointment */
      Pk_Schedule.set_vacant_occupied (i_id_inst               => l_schedule.id_instit_requested,
                                       i_id_sch_event          => l_schedule.id_sch_event,
                                       i_id_dep_clin_serv      => l_schedule.id_dcs_requested,
                                       i_id_prof               => :NEW.id_professional,
                                       i_dt_begin              => l_schedule.dt_begin
                                      );
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      l_sqlerrm := SQLERRM;
      Pk_Schedule.LOG (i_where_is_at      => 'A_I_SPO_VACANCIES',
                       i_sqlerrm          => l_sqlerrm || ' / id_schedule[' || l_schedule.id_schedule || ']',
                       i_scope            => 'ERROR'
                      );
--      RAISE;
END a_i_spo_vacancies;
/

DROP TRIGGER A_I_SPO_VACANCIES;
