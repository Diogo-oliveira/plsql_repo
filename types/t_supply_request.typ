CREATE OR REPLACE TYPE t_supply_request AS OBJECT
(
    id_patient         NUMBER(24),
    id_episode         NUMBER(24),
    id_room_req        NUMBER(24),
    desc_room          VARCHAR2(4000 CHAR),
    code_room          VARCHAR2(100 CHAR),
    code_department    VARCHAR2(100 CHAR),
    code_dept          VARCHAR2(100 CHAR),
    num_clin_record    VARCHAR2(100 CHAR),
    id_supply_request  NUMBER(24),
    id_supply_workflow NUMBER(24),
    flg_status         VARCHAR2(2 CHAR),
    rank               NUMBER(24)
)
;
/