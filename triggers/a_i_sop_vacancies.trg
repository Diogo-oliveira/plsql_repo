CREATE OR REPLACE TRIGGER a_i_sop_vacancies
   AFTER INSERT
   ON alert.SCHEDULE_OUTP
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
   
when (NEW.flg_vacancy != 'V')
DECLARE
   tmpvar       NUMBER;
/******************************************************************************
   NAME:       A_I_SOP_VACANCIES
   PURPOSE:    Remove one vacancy to the specialty consultation when this isn't
               of type unplanned

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17-10-2006  Ricardo Pinho    1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     A_I_SOP_VACANCIES
      Sysdate:         17-10-2006
      Date and Time:   17-10-2006, 18:24:11, and 17-10-2006 18:24:11
******************************************************************************/
   l_event      SCH_EVENT%ROWTYPE;
   l_schedule   SCHEDULE%ROWTYPE;
   l_sqlerrm    VARCHAR2 (4000);
   l_error      VARCHAR2 (4000);
BEGIN
   SELECT s.*
     INTO l_schedule
     FROM SCHEDULE s
    WHERE s.id_schedule = :NEW.id_schedule;

   /* get correspondent event */
   SELECT se.*
     INTO l_event
     FROM SCH_EVENT se
    WHERE se.id_sch_event = l_schedule.id_sch_event;

   /* if it's a speciality consultation */
   IF l_event.intern_name IN ('FIRST_SPEC_CONSULT', 'SUBS_SPEC_CONSULT') THEN
      /* if it's not an overbooking appointment */
      Pk_Schedule.set_vacant_occupied (i_id_inst               => l_schedule.id_instit_requested,
                                       i_id_dep_clin_serv      => l_schedule.id_dcs_requested,
                                       i_id_sch_event          => l_schedule.id_sch_event,
                                       i_dt_begin              => l_schedule.dt_begin
                                      );
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      l_sqlerrm := SQLERRM;
      Pk_Schedule.LOG (i_where_is_at => 'A_I_SOP_VACANCIES', i_sqlerrm => l_sqlerrm|| ' / id_schedule[' || l_schedule.id_schedule || ']', I_SCOPE => 'ERROR');
     -- RAISE;
END a_i_sop_vacancies;
/

DROP TRIGGER A_I_SOP_VACANCIES;
