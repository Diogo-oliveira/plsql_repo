CREATE OR REPLACE TYPE "T_REC_MATCH_INFO" AS OBJECT
(
    id_pbm               NUMBER,
    id_patient           NUMBER,
    patient_match        VARCHAR2(1 CHAR),
    id_presc             NUMBER,
    presc_match          VARCHAR2(1 CHAR),
    id_presc_plan        NUMBER,
    id_product           VARCHAR2(30 CHAR),
    id_product_supplier  VARCHAR2(30 CHAR),
    product_match        VARCHAR2(1 CHAR),
    id_inn               VARCHAR2(30 CHAR),
    id_inn_supplier      VARCHAR2(30 CHAR),
    inn_match            VARCHAR2(1 CHAR),
    id_strength          VARCHAR2(30 CHAR),
    id_strength_supplier VARCHAR2(30 CHAR),
    strength_match       VARCHAR2(1 CHAR),
    id_route             VARCHAR2(30 CHAR),
    id_route_supplier    VARCHAR2(30 CHAR),
    route_match          VARCHAR2(1 CHAR),
    dose_value           NUMBER,
    id_unit_dose         NUMBER,
    dose_match           VARCHAR2(1 CHAR),
    dt_plan              TIMESTAMP(6) WITH LOCAL TIME ZONE,
    searchable_date      VARCHAR2(1 CHAR),
    valid_date           VARCHAR2(1 CHAR)
)
;
