-- CHANGED BY: Pedro Albuquerque
-- CHANGED DATE: 2009-AUG-17
-- CHANGING REASON: posologias irregulares
CREATE OR REPLACE TYPE t_presc_most_freq AS OBJECT
(
  id_presc_freq_det      	NUMBER(24),
  ntake_value 				NUMBER(24,4),
  ntake_value_unit    		number(24),
  duration_value           	number(24),
  duration_value_unit       NUMBER(24),
  id_presc_frequency_type   NUMBER(24),
  id_irregular_directions 	NUMBER(24),
  time              		interval day(3) to second(3)
);
-- CHANGE END Pedro Albuquerque
