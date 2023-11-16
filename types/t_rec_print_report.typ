CREATE OR REPLACE TYPE t_rec_print_report AS OBJECT
(
    id_reports    NUMBER(24),
    desc_report   VARCHAR2(4000),
    flg_active    VARCHAR2(1 CHAR),
    column_values table_varchar,

    CONSTRUCTOR FUNCTION t_rec_print_report RETURN SELF AS RESULT,
    MEMBER FUNCTION get_column_values RETURN table_varchar,
    MEMBER FUNCTION to_string RETURN VARCHAR2
)
;
/

CREATE OR REPLACE TYPE BODY t_rec_print_report IS
    CONSTRUCTOR FUNCTION t_rec_print_report RETURN SELF AS RESULT IS
    BEGIN
        self.id_reports    := NULL;
        self.desc_report   := NULL;
        self.flg_active    := NULL;
        self.column_values := table_varchar();
        RETURN;
    END;

    MEMBER FUNCTION get_column_values RETURN table_varchar IS
    BEGIN
        RETURN self.column_values;
    END get_column_values;
    
    MEMBER FUNCTION to_string RETURN VARCHAR2 IS
    BEGIN
        RETURN 'id_reports=' || self.id_reports || ' desc_report=' || self.desc_report || ' flg_active=' || flg_active || ' column_values=' || pk_utils.to_string(self.column_values);
    END to_string;
END;
/