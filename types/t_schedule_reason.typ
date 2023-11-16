-- CHANGED BY: Telmo
-- CHANGE DATE: 18-09-2013
-- CHANGE REASON: alert-264895
CREATE TYPE t_schedule_reason IS OBJECT(
        id          NUMBER(24),
        title       VARCHAR2(4000),
        text        VARCHAR2(4000),
        order_field NUMBER(1),
        origin      VARCHAR2(2),
        id_software NUMBER(24));
-- CHANGE END: Telmo
