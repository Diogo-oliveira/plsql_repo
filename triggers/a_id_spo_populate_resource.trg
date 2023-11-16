CREATE OR REPLACE TRIGGER a_id_spo_populate_resource
   AFTER DELETE OR INSERT
   ON alert.SCH_PROF_OUTP
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
/******************************************************************************
   NAME:       SPO_POPULATE_SRE
   PURPOSE:    Populate table sch_resource. Used by the Alert Scheduler

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        13-09-2006  Ricardo Pinho    1. Created this trigger.

   NOTES:
******************************************************************************/
   l_schedule        SCHEDULE%ROWTYPE;
   l_schedule_outp   SCHEDULE_OUTP%ROWTYPE;
   l_sqlerrm         VARCHAR2 (4000);
BEGIN
--Pk_Schedule.LOG (i_where_is_at => 'A_ID_SPO_POPULATE_RESOURCE', i_sqlerrm => 'INSERT INTO SCH_RESOURCE '|| L_SCHEDULE.ID_SCHEDULE, I_SCOPE => 'DEBUG');
--RAISE_APPLICATION_ERROR( -20001, '>>'||:NEW.id_schedule_outp );
   IF INSERTING THEN
      SELECT so.*
        INTO l_schedule_outp
        FROM SCHEDULE_OUTP so
       WHERE so.id_schedule_outp = :NEW.id_schedule_outp;

      SELECT s.*
        INTO l_schedule
        FROM SCHEDULE s
       WHERE s.id_schedule = l_schedule_outp.id_schedule;

      INSERT INTO SCH_RESOURCE
                  (id_sch_resource, id_schedule, id_institution,
                   id_professional
                  )
           VALUES (seq_sch_resource.NEXTVAL, l_schedule.id_schedule, l_schedule.id_instit_requested,
                   :NEW.id_professional
                  );
   ELSIF DELETING THEN
      SELECT so.*
        INTO l_schedule_outp
        FROM SCHEDULE_OUTP so
       WHERE so.id_schedule_outp = :OLD.id_schedule_outp;

      SELECT s.*
        INTO l_schedule
        FROM SCHEDULE s
       WHERE s.id_schedule = l_schedule_outp.id_schedule;

      DELETE FROM SCH_RESOURCE sr
            WHERE sr.id_schedule = l_schedule.id_schedule AND sr.id_professional = :OLD.id_professional;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      l_sqlerrm := SQLERRM;
      Pk_Schedule.LOG (i_where_is_at => 'A_ID_SPO_POPULATE_RESOURCE', i_sqlerrm => l_sqlerrm, I_SCOPE => 'ERROR');
      RAISE;
END a_id_spo_populate_resource;
/

DROP TRIGGER A_ID_SPO_POPULATE_RESOURCE;
