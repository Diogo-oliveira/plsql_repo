


CREATE OR REPLACE TYPE t_rec_ref_comments_info AS OBJECT
(
    val        NUMBER(6),
    bg_color   VARCHAR2(35),
    fg_color   VARCHAR2(35),
    shortcut   NUMBER(24),
    status VARCHAR2(1),

    CONSTRUCTOR FUNCTION t_rec_ref_comments_info RETURN SELF AS RESULT,
    MEMBER FUNCTION get_val RETURN NUMBER,
    MEMBER FUNCTION get_bg_color RETURN VARCHAR2,
    MEMBER FUNCTION get_fg_color RETURN VARCHAR2,
    MEMBER FUNCTION get_shortcut RETURN NUMBER,
    MEMBER FUNCTION get_status RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY t_rec_ref_comments_info IS
    CONSTRUCTOR FUNCTION t_rec_ref_comments_info RETURN SELF AS RESULT IS
    BEGIN
        self.val        := NULL;
        self.bg_color   := NULL;
        self.fg_color   := NULL;
        self.shortcut   := NULL;
        self.status := NULL;
        RETURN;
    END;

    MEMBER FUNCTION get_val RETURN NUMBER IS
    BEGIN
        RETURN self.val;
    END get_val;

    MEMBER FUNCTION get_bg_color RETURN VARCHAR2 IS
    BEGIN
        RETURN self.bg_color;
    END get_bg_color;

    MEMBER FUNCTION get_fg_color RETURN VARCHAR2 IS
    BEGIN
        RETURN self.fg_color;
    END get_fg_color;

    MEMBER FUNCTION get_shortcut RETURN NUMBER IS
    BEGIN
        RETURN self.shortcut;
    END get_shortcut;

    MEMBER FUNCTION get_status RETURN VARCHAR2 IS
    BEGIN
        RETURN self.status;
    END get_status;

END;
/

          