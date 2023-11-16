CREATE OR REPLACE TYPE t_rec_exam_question_response AS OBJECT
(
    id_exam_question_response NUMBER(24),
    id_questionnaire          NUMBER(24),
    id_response               NUMBER(24),
    id_episode                NUMBER(24),
    notes                     CLOB,
    dt_last_update_tstz       TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_prof_last_update       NUMBER(24)
);
/
