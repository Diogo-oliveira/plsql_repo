CREATE OR REPLACE TYPE t_rec_wf_status_info_def AS OBJECT
(
    id_status   NUMBER(24),
    desc_status VARCHAR2(200),
    icon        VARCHAR2(200),
    color       VARCHAR2(35),
    rank        NUMBER(6),
    code_status VARCHAR2(240),

    CONSTRUCTOR FUNCTION t_rec_wf_status_info_def RETURN SELF AS RESULT
)
;
/

CREATE OR REPLACE TYPE BODY t_rec_wf_status_info_def IS
    CONSTRUCTOR FUNCTION t_rec_wf_status_info_def RETURN SELF AS RESULT IS
    BEGIN
        SELF.id_status   := NULL;
        SELF.desc_status := NULL;
        SELF.icon        := NULL;
        SELF.color       := NULL;
        SELF.rank        := NULL;
        SELF.code_status := NULL;
    
        RETURN;
    END;
END;
/