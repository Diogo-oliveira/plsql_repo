CREATE OR REPLACE TYPE t_epis_hid_det AS OBJECT
(
    id_epis_hidrics_det    NUMBER(24),
    id_epis_hidrics        NUMBER(24),
    id_epis_hidrics_line   NUMBER(24),
    id_way                 NUMBER(24),
    id_epis_hid_ftxt_way   NUMBER(24),
    id_epis_hid_ftxt_fluid NUMBER(24),
    value_hidrics          NUMBER(26, 2),
    id_professional_p      NUMBER(24),
    flg_type_hid           VARCHAR2(1 CHAR),
    id_hidrics             NUMBER(24),
    flg_type_ehd           VARCHAR2(1 CHAR),
    nr_times               NUMBER(12),
    id_professional_ehd    NUMBER(24),
    flg_status             VARCHAR2(1 CHAR),
    dt_execution_tstz      TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_creation_tstz       TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_epis_hidrics_group  NUMBER(24)
);
/