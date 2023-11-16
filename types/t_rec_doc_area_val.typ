CREATE OR REPLACE TYPE t_rec_doc_area_val force AS OBJECT
(
    id_epis_documentation NUMBER(24),
    PARENT                NUMBER(24),
    id_documentation      NUMBER(24),
    id_doc_component      NUMBER(24),
    id_doc_element_crit   NUMBER(24),
    dt_reg                VARCHAR2(4000),
    desc_doc_component    VARCHAR2(4000),
    flg_type              VARCHAR2(1),
    desc_element          VARCHAR2(4000),
    desc_element_view     VARCHAR2(4000),
    VALUE                 VARCHAR2(32767),
    flg_type_element      VARCHAR2(2),
    id_doc_area           NUMBER(24),
    rank_component        NUMBER(24),
    rank_element          NUMBER(24),
    internal_name         VARCHAR2(200 CHAR),
    desc_quantifier       VARCHAR2(32767),
    desc_quantification   VARCHAR2(32767),
    desc_qualification    VARCHAR2(32767),
    display_format        VARCHAR2(200 CHAR),
    separator             VARCHAR2(10 CHAR),
    flg_table_origin      VARCHAR2(1 CHAR),
    flg_status            VARCHAR2(1),
    value_id              VARCHAR2(4000),
    signature             VARCHAR2(4000)
);
/
