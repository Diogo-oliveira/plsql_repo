-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 04/08/2017 18:22
-- CHANGE REASON: [ALERT-332316]
CREATE OR REPLACE TYPE t_rec_ds_items_values FORCE AS OBJECT
(
    id_ds_cmpt_mkt_rel NUMBER(24),
    id_ds_component    NUMBER(24),
    internal_name      VARCHAR2(200 CHAR),
    flg_component_type VARCHAR2(1 CHAR),
    item_desc          VARCHAR2(1000 CHAR),
    item_value         NUMBER(24),
    item_alt_value     VARCHAR2(10 CHAR),
    item_xml_value     CLOB,
    item_rank          NUMBER(6)
);
/
-- CHANGE END: Pedro Henriques

-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 06/11/2017 18:22
-- CHANGE REASON: [ALERT-334042]
CREATE OR REPLACE TYPE t_rec_ds_items_values FORCE AS OBJECT
(
    id_ds_cmpt_mkt_rel NUMBER(24),
    id_ds_component    NUMBER(24),
    internal_name      VARCHAR2(200 CHAR),
    flg_component_type VARCHAR2(1 CHAR),
    item_desc          VARCHAR2(1000 CHAR),
    item_value         NUMBER(24),
    item_alt_value     VARCHAR2(20 CHAR),
    item_xml_value     CLOB,
    item_rank          NUMBER(6)
);
/
-- CHANGE END: Pedro Henriques
