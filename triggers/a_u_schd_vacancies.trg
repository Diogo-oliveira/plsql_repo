CREATE OR REPLACE TRIGGER a_u_schd_vacancies
   AFTER UPDATE OF flg_status
   ON alert.SCHEDULE
   REFERENCING NEW AS NEW OLD AS OLD
   FOR EACH ROW
DECLARE
   tmpvar            NUMBER;
/******************************************************************************
   NAME:       A_U_SCHD_VACANCIES
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        18-10-2006  Ricardo Pinho    1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     A_U_SCHD_VACANCIES
      Sysdate:         18-10-2006
      Date and Time:   18-10-2006, 14:27:21, and 18-10-2006 14:27:21
******************************************************************************/
   l_schedule_outp   SCHEDULE_OUTP%ROWTYPE;
   l_sch_event       SCH_EVENT%ROWTYPE;
   l_sch_resource    SCH_RESOURCE%ROWTYPE;
BEGIN
   BEGIN
      SELECT se.*
        INTO l_sch_event
        FROM SCH_EVENT se
       WHERE se.id_sch_event = :NEW.id_sch_event;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         /* must be a non consult event */
         RETURN;
   END;

   SELECT so.*
     INTO l_schedule_outp
     FROM SCHEDULE_OUTP so
    WHERE so.id_schedule = :NEW.id_schedule;

   BEGIN
      SELECT sr.*
        INTO l_sch_resource
        FROM SCH_RESOURCE sr
       WHERE sr.id_schedule = :NEW.id_schedule;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_sch_resource := NULL;
   END;

   /* if new status is canceled */
   IF :NEW.flg_status = 'C' THEN
      /* and it was scheduled or pending */
      IF :OLD.flg_status IN ('A', 'P') THEN
         /* and if it's a consultation */
         IF (l_sch_event.flg_consult = 'Y') THEN
            /* not unplanned */
            IF l_schedule_outp.flg_vacancy != 'V' THEN
               /* a medical consultation */
               IF (l_sch_event.flg_target_professional = 'Y' AND l_sch_event.flg_target_dep_clin_serv = 'Y') THEN
                  Pk_Schedule.LOG ('A_U_SCHD_VACANCIES', 'Free vacant', 'DEBUG');
                  Pk_Schedule.set_vacant_free (i_id_inst               => :NEW.id_instit_requested,
                                               i_id_dep_clin_serv      => :NEW.id_dcs_requested,
                                               i_id_sch_event          => :NEW.id_sch_event,
                                               i_id_prof               => l_sch_resource.id_professional,
                                               i_dt_begin              => :NEW.dt_begin
                                              );
               END IF;

               /* a specialty consultation */
               IF (l_sch_event.flg_target_professional = 'N' AND l_sch_event.flg_target_dep_clin_serv = 'Y') THEN
                  Pk_Schedule.set_vacant_free (i_id_inst               => :NEW.id_instit_requested,
                                               i_id_dep_clin_serv      => :NEW.id_dcs_requested,
                                               i_id_sch_event          => :NEW.id_sch_event,
                                               i_id_prof               => NULL,
                                               i_dt_begin              => :NEW.dt_begin
                                              );
               END IF;
            END IF;
         END IF;
      END IF;
   END IF;




                  Pk_Schedule.LOG ('A_U_SCHD_VACANCIES', 'Occ ' || :NEW.flg_status || ' ' || :OLD.flg_status || ' ' || l_sch_event.flg_consult || ' ' || l_sch_event.flg_target_professional  || ' ' || l_sch_event.flg_target_dep_clin_serv , 'DEBUG');

   /* if new status is scheduled */
   IF :NEW.flg_status = 'A' THEN
      /* and it was pending */
      IF :OLD.flg_status IN ('P') THEN
         /* and if it's a consultation */
         IF (l_sch_event.flg_consult = 'Y') THEN
            /* not unplanned */
            IF l_schedule_outp.flg_vacancy != 'V' THEN
               /* a medical consultation */
               IF (l_sch_event.flg_target_professional = 'Y' AND l_sch_event.flg_target_dep_clin_serv = 'Y') THEN


                  Pk_Schedule.LOG ('A_U_SCHD_VACANCIES', 'Occupied : ' , 'DEBUG');

                  Pk_Schedule.set_vacant_occupied (i_id_inst               => :NEW.id_instit_requested,
                                                   i_id_dep_clin_serv      => :NEW.id_dcs_requested,
                                                   i_id_sch_event          => :NEW.id_sch_event,
                                                   i_id_prof               => l_sch_resource.id_professional,
                                                   i_dt_begin              => :NEW.dt_begin
                                                  );
               END IF;

               /* a specialty consultation */
               IF (l_sch_event.flg_target_professional = 'N' AND l_sch_event.flg_target_dep_clin_serv = 'Y') THEN
                  Pk_Schedule.LOG ('A_U_SCHD_VACANCIES', 'Occupied 2: '  , 'DEBUG');

                  Pk_Schedule.set_vacant_occupied (i_id_inst               => :NEW.id_instit_requested,
                                                   i_id_dep_clin_serv      => :NEW.id_dcs_requested,
                                                   i_id_sch_event          => :NEW.id_sch_event,
                                                   i_id_prof               => NULL,
                                                   i_dt_begin              => :NEW.dt_begin
                                                  );
               END IF;
            END IF;
         END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      Pk_Schedule.LOG ('A_U_SCHD_VACANCIES', 'schedule:' || :NEW.id_schedule || ' / ' || SQLERRM, 'ERROR');
END a_u_schd_vacancies;
/

DROP TRIGGER A_U_SCHD_VACANCIES;
