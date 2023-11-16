CREATE OR REPLACE TYPE t_rec_msg AS OBJECT
(
    thread_id     NUMBER(24),
    msg_id        NUMBER(24),
    msg_subject   VARCHAR2(200 CHAR),
    msg_body      VARCHAR2(1000 CHAR),
    id_sender       NUMBER(24),
    name_sender     VARCHAR2(1000 CHAR),
    id_receiver        NUMBER(24),
    name_receiver     VARCHAR2(1000 CHAR),
    thread_status VARCHAR2(1 CHAR),
    msg_status_sender    VARCHAR2(1 CHAR),
    msg_status_receiver    VARCHAR2(1 CHAR),
    thread_level  NUMBER(24),
    msg_date      timestamp,
    flg_sender    VARCHAR2(1 CHAR),
    repr_str      VARCHAR2(200 CHAR)
);

-->t_rec_msg|type
CREATE OR REPLACE TYPE t_rec_msg AS OBJECT
(
    thread_id     NUMBER(24),
    msg_id        NUMBER(24),
    msg_subject   VARCHAR2(200 CHAR),
    msg_body      clob,
    id_sender       NUMBER(24),
    name_sender     VARCHAR2(1000 CHAR),
    id_receiver        NUMBER(24),
    name_receiver     VARCHAR2(1000 CHAR),
    thread_status VARCHAR2(1 CHAR),
    msg_status_sender    VARCHAR2(1 CHAR),
    msg_status_receiver    VARCHAR2(1 CHAR),
    thread_level  NUMBER(24),
    msg_date      timestamp,
    flg_sender    VARCHAR2(1 CHAR),
    repr_str      VARCHAR2(200 CHAR)
);