-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 10/05/2017 09:48
-- CHANGE REASON: [ALERT_330656] Clean unused columns in table product and product medication
CREATE OR REPLACE TYPE t_rec_cpoe_med_task force AS OBJECT
(
       id_presc                          NUMBER(24, 0),
       id_presc_directions               NUMBER(24, 0),
       id_status                         NUMBER(24, 0),
       id_notes                          NUMBER(24, 0),
       id_cds                            NUMBER(24, 0),
       id_prof_create                    NUMBER(24, 0),
       id_prof_upd                       NUMBER(24, 0),
       id_professional_co_sign           NUMBER(24, 0),
       task_group_id                     NUMBER(24, 0),
       task_group_status_rank            NUMBER(24, 0),       
       flg_edited                        VARCHAR2(1 CHAR),
       flg_prod_replace                  VARCHAR2(1 CHAR),
       task_group_flg_edited             VARCHAR2(1 CHAR),
       id_route                          VARCHAR2(30 CHAR),
       id_route_supplier                 VARCHAR2(30 CHAR),
       id_status_desc                    VARCHAR2(1000 CHAR),
       sos_take_condition                VARCHAR2(1000 CHAR),
       dt_begin                          TIMESTAMP(6) WITH LOCAL TIME ZONE,
       dt_end                            TIMESTAMP(6) WITH LOCAL TIME ZONE,
       dt_last_update                    TIMESTAMP(6) WITH LOCAL TIME ZONE,
       dt_first_valid_plan               TIMESTAMP(6) WITH LOCAL TIME ZONE,              
       dt_validation_co_sign             TIMESTAMP(6) WITH LOCAL TIME ZONE,
       task_group_date                   TIMESTAMP(6) WITH LOCAL TIME ZONE
);
/
-- CHANGE END: rui.mendonca
