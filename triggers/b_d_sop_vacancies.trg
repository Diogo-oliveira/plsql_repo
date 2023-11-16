CREATE OR REPLACE TRIGGER b_d_sop_vacancies
   BEFORE DELETE
   ON alert.SCHEDULE_OUTP
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
   
when (NEW.flg_vacancy != 'V')
DECLARE
   tmpvar       NUMBER;
/******************************************************************************
   NAME:       B_D_SOP_VACANCIES
   PURPOSE:    Add one vacancy to the specialty consultation

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18-10-2006  Ricardo Pinho    1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     B_D_SOP_VACANCIES
      Sysdate:         18-10-2006
      Date and Time:   18-10-2006, 9:12:15, and 18-10-2006 9:12:15
******************************************************************************/
   l_event      SCH_EVENT%ROWTYPE;
   l_schedule   SCHEDULE%ROWTYPE;
   l_sqlerrm    VARCHAR2 (4000);
BEGIN
   SELECT s.*
     INTO l_schedule
     FROM SCHEDULE s
    WHERE s.id_schedule = :OLD.id_schedule;

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
      Pk_Schedule.LOG (i_where_is_at => 'B_D_SOP_VACANCIES', i_sqlerrm => l_sqlerrm|| ' / id_schedule[' || l_schedule.id_schedule || ']', I_SCOPE => 'ERROR');
     -- RAISE;
END b_d_sop_vacancies;
/

DROP TRIGGER B_D_SOP_VACANCIES;
