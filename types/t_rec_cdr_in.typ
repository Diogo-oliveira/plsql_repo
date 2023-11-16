CREATE OR REPLACE TYPE t_rec_cdr_in FORCE AS OBJECT
(
-- represents the input given to the engine
    id_cdr_concept NUMBER(24), -- rule concept identifier
    id_element     VARCHAR2(255 CHAR), -- parameter identifier
    dose           NUMBER(24, 3), -- dosage value
    id_dose_umea   NUMBER(24), -- dosage value measurement unit
    route_id       VARCHAR2(255 CHAR), -- administration route identifier
    id_task_type   NUMBER(24), -- related task type identifier
    id_task_req    VARCHAR2(255 CHAR), -- related task request identifier
    id_user_elem   VARCHAR2(255 CHAR), -- related user element identifier

    CONSTRUCTOR FUNCTION t_rec_cdr_in RETURN SELF AS RESULT
)
/
