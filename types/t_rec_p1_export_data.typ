CREATE OR REPLACE TYPE t_rec_p1_export_data AS OBJECT
(
    id             NUMBER(24),
    id_parent      NUMBER(24),
    id_req         NUMBER(24),
    title          VARCHAR2(1000 CHAR),
    text           VARCHAR2(1000 CHAR),
    dt_insert      VARCHAR2(50 CHAR),
    prof_name      VARCHAR2(200 CHAR),
    prof_spec      VARCHAR2(200 CHAR),
    flg_type       VARCHAR2(2 CHAR),
    flg_status     VARCHAR2(2 CHAR),
    id_institution NUMBER(24),
    flg_priority   VARCHAR2(1 CHAR),
    flg_home       VARCHAR2(1 CHAR),

    CONSTRUCTOR FUNCTION t_rec_p1_export_data RETURN SELF AS RESULT
)
;
/

CREATE OR REPLACE TYPE BODY t_rec_p1_export_data IS
    CONSTRUCTOR FUNCTION t_rec_p1_export_data RETURN SELF AS RESULT IS
    BEGIN
    
        self.id             := NULL;
        self.id_parent      := NULL;
        self.id_req         := NULL;
        self.title          := NULL;
        self.text           := NULL;
        self.dt_insert      := NULL;
        self.prof_name      := NULL;
        self.prof_spec      := NULL;
        self.flg_type       := NULL;
        self.flg_status     := NULL;
        self.id_institution := NULL;
        self.flg_priority   := NULL;
        self.flg_home       := NULL;
    
        RETURN;
    END;
END;
/