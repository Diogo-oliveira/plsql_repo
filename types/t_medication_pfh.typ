CREATE OR REPLACE TYPE t_medication_pfh AS OBJECT
(
    g_id_presc_mci_desc_long VARCHAR2(1000 CHAR),
    id_protocols             NUMBER(24),
    id_status                NUMBER(24),
    id_episode               NUMBER(24),
    id_visit                 NUMBER(24),
    id_workflow              NUMBER(24),
    id_drug                  table_varchar
)
/