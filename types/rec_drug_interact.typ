CREATE OR REPLACE TYPE rec_drug_interact AS OBJECT
(
    id_drug     VARCHAR2(255),
    ddi         VARCHAR2(255),
    interddi    VARCHAR2(255),
    ddi_sld     VARCHAR2(255),
    flg_type    VARCHAR2(1),
    id_presc    NUMBER(24),
    id_drug_ux  VARCHAR2(255),
    presc_type  VARCHAR2(2),
    flg_type_ux VARCHAR2(1)
);
/