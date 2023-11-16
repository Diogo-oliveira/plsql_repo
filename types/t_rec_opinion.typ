CREATE OR REPLACE TYPE t_rec_opinion AS OBJECT
(
    id_opinion      NUMBER(24),
    flg_state       VARCHAR2(30),
    dt_problem_str  VARCHAR2(100),
    dt_problem_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    desc_problem    VARCHAR2(4000)
)
/
