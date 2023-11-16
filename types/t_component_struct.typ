
CREATE OR REPLACE TYPE "T_COMPONENT_STRUCT" AS OBJECT
(
    id_drug              VARCHAR2(255),
    qty                  NUMBER(24, 4),
    id_measure_unit      VARCHAR2(30),
    desc_measure_unit    VARCHAR2(4000),
    drug_flg_type        VARCHAR2(1),
    drug_chnm_id         VARCHAR2(255),
    drug_descr           VARCHAR2(255),
    drug_form_farm_id    VARCHAR2(255),
    drug_form_farm_descr VARCHAR2(255),
    drug_route_id        VARCHAR2(255),
    drug_route_descr     VARCHAR2(255)
);
