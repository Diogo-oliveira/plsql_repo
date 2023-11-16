CREATE OR REPLACE TYPE t_rec_consult_diff force AS OBJECT
(
    speciality_b           VARCHAR2(4000),
    speciality_a           VARCHAR2(4000),
    request_reason_b       VARCHAR2(4000),
    request_reason_a       VARCHAR2(4000),
    request_reason_ft_b    VARCHAR2(4000),
    request_reason_ft_a    VARCHAR2(4000),
    name_prof_questioned_b VARCHAR2(4000),
    name_prof_questioned_a VARCHAR2(4000),
    notes_b                CLOB,
    notes_a                CLOB,
    state_b                VARCHAR2(4000),
    state_a                VARCHAR2(4000),
    notes_cancel_b         VARCHAR2(4000),
    notes_cancel_a         VARCHAR2(4000),
    cancel_reason_b        VARCHAR2(4000),
    cancel_reason_a        VARCHAR2(4000),
    registered_b           VARCHAR2(4000),
    registered_a           VARCHAR2(4000),
    create_time            VARCHAR2(4000)
);
/