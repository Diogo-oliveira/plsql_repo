CREATE OR REPLACE TYPE t_rec_cdrip force AS OBJECT
(
-- represents a fully instantiated rule condition parameter
-- should only be used to check conditions validity
    id_cdr_inst_param NUMBER(24), -- rule instance parameter identifier
    id_cdr_instance   NUMBER(24), -- rule instance identifier
    id_cdr_condition  NUMBER(24), -- rule condition identifier
    id_cdr_parameter  NUMBER(24), -- rule parameter identifier
    id_cdr_concept    NUMBER(24), -- rule concept identifier
    flg_identifiable  VARCHAR2(1 CHAR), -- must this parameter be identified? Y/N
    flg_valuable      VARCHAR2(1 CHAR), -- must this parameter be valued? Y/N
    flg_condition     VARCHAR2(1 CHAR), -- rule condition operator: (A)nd, (O)r
    flg_deny          VARCHAR2(1 CHAR), -- is condition denied? Y/N
    flg_dosage        VARCHAR2(1 CHAR), -- condition uses dosage attributes? Y/N
    id_element        VARCHAR2(255 CHAR), -- parameter identifier
    validity          NUMBER(24, 3), -- validity value
    id_validity_umea  NUMBER(24), -- validity time measurement unit
    val_min           NUMBER(24, 3), -- left domain bound
    val_max           NUMBER(24, 3), -- right domain bound
    id_domain_umea    NUMBER(24), -- domain measurement unit
    route_id          VARCHAR2(255 CHAR), -- administration route identifier
    val_list          table_varchar, -- values list
    cond_count        NUMBER(24), -- number of conditions in instance
    cond_par_count    NUMBER(24), -- number of parameters in condition

    CONSTRUCTOR FUNCTION t_rec_cdrip RETURN SELF AS RESULT
)
/
