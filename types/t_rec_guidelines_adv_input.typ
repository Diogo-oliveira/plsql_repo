CREATE OR REPLACE TYPE t_rec_guidelines_adv_input AS OBJECT
(
    id_advanced_input           NUMBER(6),
    id_advanced_input_field             NUMBER(24),
    id_advanced_input_field_det         NUMBER(24),
		id_adv_input_link                   NUMBER(24),
		value                               VARCHAR2(1000),
		value_date                          TIMESTAMP WITH TIME ZONE
);  
/
