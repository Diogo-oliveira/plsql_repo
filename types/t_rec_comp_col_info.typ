CREATE OR REPLACE TYPE t_rec_comp_col_info AS OBJECT
(
    col_name     VARCHAR2(30 CHAR),
    col_type     VARCHAR2(25 CHAR),
    col_size     NUMBER(12),
    col_nullable VARCHAR2(1 CHAR),
    CONSTRUCTOR FUNCTION t_rec_comp_col_info
    (
        col_name     IN VARCHAR2,
        col_type     IN VARCHAR2,
        col_size     IN NUMBER,
        col_nullable IN VARCHAR2 DEFAULT 'Y'
    ) RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY t_rec_comp_col_info IS
    CONSTRUCTOR FUNCTION t_rec_comp_col_info
    (
        col_name     IN VARCHAR2,
        col_type     IN VARCHAR2,
        col_size     IN NUMBER,
        col_nullable IN VARCHAR2 DEFAULT 'Y'
    ) RETURN SELF AS RESULT IS
    BEGIN
        IF col_name IS NULL
           OR col_type IS NULL
        THEN
            raise_application_error(-20001, 'COL_NAME AND COL_TYPE MUST BE FILLED');
        END IF;

        IF col_type NOT IN ('NUM', 'STR', 'DATE', 'FLG', 'TBL_NUM', 'TBL_STR')
        THEN
            raise_application_error(-20001, 'INVALID TYPE');
        END IF;

        IF col_type = 'FLG'
           AND nvl(col_size, -1) <= 0
        THEN
            raise_application_error(-20001, 'TYPE ''FLG'' MUST HAVE A SIZE GREATER THEN 0');
        END IF;

        SELF.col_name     := col_name;
        SELF.col_type     := col_type;
        SELF.col_size     := col_size;
        SELF.col_nullable := col_nullable;

        RETURN;
    END;
END;
/
