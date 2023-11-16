CREATE OR REPLACE TYPE t_rec_lab_room_instit force AS OBJECT
(
    id_harvest               NUMBER(24),
    id_analysis              table_number,
    id_room_instit           VARCHAR2(100 CHAR),
    desc_room_instit         VARCHAR2(4000 CHAR),
    institution_abbreviation VARCHAR2(200 CHAR),
    flg_type                 VARCHAR2(1 CHAR),
    rank                     NUMBER(6),
    flg_room_instit          VARCHAR2(1 CHAR),
    flg_default              VARCHAR2(1 CHAR)
);
/
