CREATE OR REPLACE TYPE t_question_response force AS OBJECT
(
    id_task                   NUMBER(24),
    id_order_set_process_task NUMBER(24),
    id_task_type              NUMBER(24),
    id_questionnaire          NUMBER(24),
    id_response               NUMBER(24),
    notes                     VARCHAR2(1000),
    rank                      NUMBER(24)
)
;
/
