
create table advanced_input_field_unit
(id_advanced_input_field_unit number(24) not null,
 id_advanced_input_field number(24) not null,
 id_unit_measure number(24) not null);

comment on table advanced_input_field_unit
  is 'Possible measure units for each field';
comment on column advanced_input_field_unit.id_advanced_input_field_unit
  is 'Primary key';
comment on column advanced_input_field_unit.id_advanced_input_field
  is 'Field ID';
comment on column advanced_input_field_unit.id_unit_measure
  is 'Measure unit ID';
  
  
  
ALTER TABLE ADVANCED_INPUT_FIELD_UNIT ADD RANK NUMBER(12);
COMMENT ON COLUMN ADVANCED_INPUT_FIELD_UNIT.RANK IS 'Rank for order appearance';