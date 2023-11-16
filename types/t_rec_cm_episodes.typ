-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 19/09/2012 12:09
-- CHANGE REASON: [ALERT-240056] - Crisis Machine - Miss the services, rooms and beds in the patient
CREATE OR REPLACE TYPE t_rec_cm_episodes FORCE IS OBJECT
(
    id_episode          NUMBER(24),
    id_patient          NUMBER(24),
    id_schedule         NUMBER(24),
    dt_target           TIMESTAMP
        WITH LOCAL TIME ZONE,
    dt_last_interaction TIMESTAMP
        WITH LOCAL TIME ZONE,
    id_software         NUMBER(24)
);
-- CHANGE END: Gustavo Serrano
