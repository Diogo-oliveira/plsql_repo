CREATE OR REPLACE TYPE tr_ds_section force AS OBJECT
(
    id_ds_cmpt_mkt_rel        NUMBER(24),
    id_market                 NUMBER(24),
    id_ds_component_parent    NUMBER(24),
    internal_name_parent      VARCHAR2(200),
    flg_component_type_parent VARCHAR2(1),
    id_ds_component_child     NUMBER(24),
    internal_name_child       VARCHAR2(200),
    flg_component_type_child  VARCHAR2(1),
    rank                      NUMBER(24),
    gender                    VARCHAR2(1 CHAR),
    age_min_value             NUMBER(5,2),
    age_min_unit_measure      NUMBER(24),
    age_max_value             NUMBER(5,2),
    age_max_unit_measure      NUMBER(24),
    id_unit_measure           NUMBER(24),
    id_unit_measure_subtype   NUMBER(24),
      max_len                   NUMBER(24),
      min_value                 NUMBER(24),
      max_value                 NUMBER(24),
    rn number(24)
)
;