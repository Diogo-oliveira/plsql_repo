CREATE OR REPLACE TYPE t_procedures_execution force AS OBJECT
(
    id_interv_presc_plan NUMBER(24),
    registry             VARCHAR2(1000 CHAR),
    desc_procedure       VARCHAR2(1000 CHAR),
    prof_perform         VARCHAR2(1000 CHAR),
    start_time           VARCHAR2(1000 CHAR),
    end_time             VARCHAR2(1000 CHAR),
    next_perform_date    VARCHAR2(1000 CHAR),
    desc_modifiers       VARCHAR2(1000 CHAR),
    desc_supplies        VARCHAR2(1000 CHAR),
    desc_time_out        VARCHAR2(1000 CHAR),
    desc_perform         CLOB,
    cancel_reason        VARCHAR2(1000 CHAR),
    cancel_notes         VARCHAR2(1000 CHAR),
    dt_ord               VARCHAR2(200 CHAR),    
    dt_last_update        TIMESTAMP(6)
)
;
/
