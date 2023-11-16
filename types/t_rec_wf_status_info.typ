CREATE OR REPLACE TYPE t_rec_wf_status_info AS OBJECT
(
    id_workflow NUMBER(12),
    id_status   NUMBER(24),
    icon        VARCHAR2(200),
    color       VARCHAR2(35),
    rank        NUMBER(6),
    desc_status VARCHAR2(4000),
    flg_insert  VARCHAR2(1),
    flg_update  VARCHAR2(1),
    flg_delete  VARCHAR2(1),
    flg_read    VARCHAR2(1),
    FUNCTION    VARCHAR2(2000),

    CONSTRUCTOR FUNCTION t_rec_wf_status_info RETURN SELF AS RESULT,
    MEMBER FUNCTION get_desc_status RETURN VARCHAR2,
    MEMBER FUNCTION get_color RETURN VARCHAR2,
    MEMBER FUNCTION get_icon RETURN VARCHAR2,
    MEMBER FUNCTION get_rank RETURN VARCHAR2,
    MEMBER FUNCTION get_flg_update RETURN VARCHAR2

)
/

CREATE OR REPLACE TYPE BODY t_rec_wf_status_info IS
    CONSTRUCTOR FUNCTION t_rec_wf_status_info RETURN SELF AS RESULT IS
    BEGIN
        self.id_workflow := NULL;
        self.id_status   := NULL;
        self.icon        := NULL;
        self.color       := NULL;
        self.rank        := NULL;
        self.desc_status := NULL;
        self.flg_insert  := NULL;
        self.flg_update  := NULL;
        self.flg_delete  := NULL;
        self.flg_read    := NULL;
        self.function    := NULL;

        RETURN;
    END;


    MEMBER FUNCTION get_desc_status RETURN VARCHAR2 IS
    BEGIN
        RETURN self.desc_status;
    END get_desc_status;

    MEMBER FUNCTION get_color RETURN VARCHAR2 IS
    BEGIN
        RETURN self.color;
    END get_color;

    MEMBER FUNCTION get_icon RETURN VARCHAR2 IS
    BEGIN
        RETURN self.icon;
    END get_icon;

    MEMBER FUNCTION get_rank RETURN VARCHAR2 IS
    BEGIN
        RETURN self.rank;
    END get_rank;

    MEMBER FUNCTION get_flg_update RETURN VARCHAR2 IS
    BEGIN
        RETURN self.flg_update;
    END get_flg_update;

END;
/