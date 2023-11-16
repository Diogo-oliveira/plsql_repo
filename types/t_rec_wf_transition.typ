DROP TYPE t_rec_wf_transition;

CREATE OR REPLACE TYPE t_rec_wf_transition AS OBJECT
(
    id_workflow         NUMBER(24),
    id_status_begin     NUMBER(24),
    id_workflow_action  NUMBER(24),
    id_status_end       NUMBER(24),
    icon                VARCHAR2(200),
    desc_transition     VARCHAR2(4000),
    rank                NUMBER(6),
    flg_auto_transition VARCHAR2(1),
    flg_visible         VARCHAR2(1),    
    CONSTRUCTOR FUNCTION t_rec_wf_transition RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_wf_transition IS
    CONSTRUCTOR FUNCTION t_rec_wf_transition RETURN SELF AS RESULT IS
    BEGIN
        SELF.id_workflow         := NULL;
        SELF.id_status_begin     := NULL;
        SELF.id_workflow_action  := NULL;
        SELF.id_status_end       := NULL;
        SELF.icon                := NULL;
        SELF.desc_transition     := NULL;
        SELF.rank                := NULL;
        SELF.flg_auto_transition := NULL;
        SELF.flg_visible         := NULL;    
        RETURN;
    END;
END;
/