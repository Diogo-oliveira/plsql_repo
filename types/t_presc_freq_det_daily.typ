-- CHANGED BY: Pedro Albuquerque
-- CHANGED DATE: 2009-AUG-17
-- CHANGING REASON: posologias irregulares
CREATE OR REPLACE TYPE t_presc_freq_det_daily AS OBJECT
(
  id_presc_freq_det      	NUMBER(24),
  ntake_value 				NUMBER(24,4),
  ntake_value_unit    		number(24),
  id_presc_frequency_type   NUMBER(24),
  other_freq_type          	varchar2(2),
  exact_value				number(24)
);
-- CHANGE END Pedro Albuquerque
