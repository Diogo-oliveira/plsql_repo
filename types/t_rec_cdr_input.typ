-- CHANGED BY: Mário Mineiro
-- CHANGE DATE: 12/12/2014
-- CHANGE REASON: [ALERT-304361]
CREATE OR REPLACE TYPE t_rec_cdr_input force AS OBJECT
(
    i_type         VARCHAR2(300), -- says if its a concept or task type
    i_concept_task table_number, -- concept types and task types
    i_elements     table_varchar, -- elements and task reqs
    i_dose         table_number,
    i_dose_um      table_number,
    i_route        table_varchar,
    i_id_task_type NUMBER(24)
)
;
-- CHANGE END: Mário Mineiro
/
