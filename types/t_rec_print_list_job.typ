CREATE OR REPLACE TYPE t_rec_print_list_job AS OBJECT
(
    id_print_list_job   NUMBER(24),
    id_print_list_area  NUMBER(24),    
    title_desc          VARCHAR2(1000 CHAR),
    subtitle_desc       VARCHAR2(1000 CHAR),
    
    CONSTRUCTOR FUNCTION t_rec_print_list_job RETURN SELF AS RESULT,
    MEMBER FUNCTION get_title RETURN VARCHAR2,
    MEMBER FUNCTION get_subtitle RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY t_rec_print_list_job IS
    CONSTRUCTOR FUNCTION t_rec_print_list_job RETURN SELF AS RESULT IS
    BEGIN
        self.id_print_list_job  := NULL;
        self.id_print_list_area := NULL;
        self.title_desc         := NULL;
        self.subtitle_desc      := NULL;
        RETURN;
    END;

    MEMBER FUNCTION get_title RETURN VARCHAR2 IS
    BEGIN
        RETURN self.title_desc;
    END get_title;

    MEMBER FUNCTION get_subtitle RETURN VARCHAR2 IS
    BEGIN
        RETURN self.subtitle_desc;
    END get_subtitle;
END;
/