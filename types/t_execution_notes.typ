-- CHANGED BY: Diogo Oliveira
-- CHANGED DATE: 2017-09-01
-- CHANGE REASON: ALERT-332707 

CREATE OR REPLACE TYPE t_execution_notes AS OBJECT
(
          l_presc_plan        number(24),--interv_presc_plan.id_interv_presc_plan%type,
          l_documentation     number(24),--documentation.id_documentation%type,
          l_notes             clob
);
/

-- CHANGED END: Diogo Oliveira