CREATE OR REPLACE TYPE t_rec_inst_fields AS OBJECT
(
    id_institution NUMBER(24),
    id_field_market NUMBER(24),
    field_name      VARCHAR2(1000 CHAR),
    field_value     VARCHAR2(1000 CHAR),
    id_market       number(24)
)
;
