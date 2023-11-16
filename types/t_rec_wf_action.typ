-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2014-APR-17
-- CHANGED REASON: ALERT-275664
CREATE OR REPLACE TYPE t_rec_wf_action AS OBJECT
(
    id_action          NUMBER(24),
    id_workflow        NUMBER(24),
    id_status_begin    NUMBER(24),
    id_status_end      NUMBER(24),
    code_wf_action     VARCHAR2(200 CHAR),
    id_wf_action       NUMBER(24),
    id_workflow_action NUMBER(24),

    CONSTRUCTOR FUNCTION t_rec_wf_action RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_wf_action IS
    CONSTRUCTOR FUNCTION t_rec_wf_action RETURN SELF AS RESULT IS
    BEGIN

        self.id_action          := NULL;
        self.id_workflow        := NULL;
        self.id_status_begin    := NULL;
        self.id_status_end      := NULL;
        self.code_wf_action     := NULL;
        self.id_wf_action       := NULL;
        self.id_workflow_action := NULL;

        RETURN;
    END;
END;
/
-- CHANGE END: Ana Monteiro