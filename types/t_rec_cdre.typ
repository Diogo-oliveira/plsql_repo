CREATE OR REPLACE TYPE t_rec_cdre FORCE AS OBJECT
(
-- represents the an engine event
    id_cdr_inst_par_action NUMBER(24), -- rule instance parameter action identifier
    id_cdr_instance        NUMBER(24), -- rule instance identifier
    event_span             NUMBER(24, 3), -- minimum time between events
    id_event_span_umea     NUMBER(24), --minimum time between events time measurement unit
    flg_first_time         VARCHAR2(1 CHAR), --fire action only the first time in session? Y/N

    CONSTRUCTOR FUNCTION t_rec_cdre RETURN SELF AS RESULT
)
/
