CREATE OR REPLACE TYPE t_rec_rcm AS OBJECT
(
    id_patient         NUMBER(24),
    id_rcm             NUMBER(24),
    id_rcm_det         NUMBER(24),
    id_rcm_type        NUMBER(24),
    rcm_text           CLOB,
    id_rcm_orig        NUMBER(24),
    id_rcm_orig_value  VARCHAR2(200 CHAR),
    id_workflow        NUMBER(24),
    id_status          NUMBER(24),
    dt_status          TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_prof_status     NUMBER(24),
    id_episode         NUMBER(24),
    id_workflow_action NUMBER(24),
    notes              CLOB,

    CONSTRUCTOR FUNCTION t_rec_rcm RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_rcm IS
    CONSTRUCTOR FUNCTION t_rec_rcm RETURN SELF AS RESULT IS
    BEGIN
        self.id_patient         := NULL;
        self.id_rcm             := NULL;
        self.id_rcm_det         := NULL;
        self.id_rcm_type        := NULL;
        self.rcm_text           := NULL;
        self.id_rcm_orig        := NULL;
        self.id_rcm_orig_value  := NULL;
        self.id_workflow        := NULL;
        self.id_status          := NULL;
        self.dt_status          := NULL;
        self.id_prof_status     := NULL;
        self.id_episode         := NULL;
        self.id_workflow_action := NULL;
        self.notes              := NULL;
    
        RETURN;
    END;
END;
/