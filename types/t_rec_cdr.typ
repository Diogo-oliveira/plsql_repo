CREATE OR REPLACE TYPE t_rec_cdr AS OBJECT
(
-- represents an semi-instantiated rule condition parameter
-- should only be used to check conditions instance applicability
    id_cdr_instance  NUMBER(24), -- rule instance identifier
    id_cdr_condition NUMBER(24), -- rule condition identifier
    id_cdr_parameter NUMBER(24), -- rule parameter identifier
    id_cdr_concept   NUMBER(24), -- rule concept identifier
    flg_dosage       VARCHAR2(1 CHAR), -- condition uses dosage attributes? Y/N
    id_element       VARCHAR2(255 CHAR), -- parameter identifier
    cond_count       NUMBER(3), -- number of conditions in instance
    cond_par_count   NUMBER(3), -- number of parameters in condition

    CONSTRUCTOR FUNCTION t_rec_cdr RETURN SELF AS RESULT
)
/
