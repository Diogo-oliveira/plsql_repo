-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 21/04/2010 11:26
-- CHANGE REASON: [ALERT-91154] Registration POS
CREATE OR REPLACE TYPE t_rec_pos_req_detail IS OBJECT
(
    id_sr_pos_schedule NUMBER(24),
    id_prof_req       NUMBER(24),
    dt_req            TIMESTAMP WITH LOCAL TIME ZONE,
    req_notes         VARCHAR2(1000 CHAR),
    id_sr_pos_status  NUMBER(24),
    desc_decision     VARCHAR2(800),
    valid_days        NUMBER(6),
    dt_valid          TIMESTAMP WITH LOCAL TIME ZONE,
    decision_notes    VARCHAR2(1000 CHAR),
    id_prof_reg       NUMBER(24),
    dt_reg            TIMESTAMP WITH LOCAL TIME ZONE,
    sch_sr_id_episode NUMBER(24),
flg_status        VARCHAR2(2),
dt_pos_suggested  TIMESTAMP WITH LOCAL TIME ZONE
)
/
-- CHANGE END: Gustavo Serrano