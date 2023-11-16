-->T_REC_PRESC_PLAN_INFO|type
CREATE OR REPLACE TYPE "T_REC_PRESC_PLAN_INFO" AS OBJECT
(
    id_pbm               NUMBER,
    id_patient           NUMBER,
    id_presc             NUMBER,
    id_presc_plan        NUMBER,
    id_product           VARCHAR2(30 CHAR),
    id_product_supplier  VARCHAR2(30 CHAR),
    id_inn               VARCHAR2(30 CHAR),
    id_inn_supplier      VARCHAR2(30 CHAR),
    id_strength          VARCHAR2(30 CHAR),
    id_strength_supplier VARCHAR2(30 CHAR),
    id_route             VARCHAR2(30 CHAR),
    id_route_supplier    VARCHAR2(30 CHAR),
    dose_value           NUMBER,
    id_unit_dose         NUMBER,
    dt_plan              TIMESTAMP,
    flg_sos              VARCHAR2(1 CHAR)
)
;
