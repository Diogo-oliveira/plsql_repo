declare
e_dependencies exception;
pragma exception_init(e_dependencies, -02303);
begin
execute immediate
'CREATE OR REPLACE TYPE t_rec_lab_test_info AS OBJECT
(
-- represents a lab test
    code_analysis            VARCHAR2(1000 CHAR),
    id_analysis              NUMBER(24),
    TYPE                     VARCHAR2(1 CHAR),
    flg_result               VARCHAR2(1 CHAR),
    flg_col_inst             VARCHAR2(1 CHAR),
    id_lab                   NUMBER(24),
    desc_lab                 VARCHAR2(1000 CHAR),
    flg_collection_author    VARCHAR2(1 CHAR),
    id_analysis_codification NUMBER(24),
    id_codification          NUMBER(24),
    desc_codification        VARCHAR2(1000 CHAR),
    desc_exterior            VARCHAR2(800 CHAR),

    CONSTRUCTOR FUNCTION t_rec_lab_test_info RETURN SELF AS RESULT
)';
exception when e_dependencies then
dbms_output.put_line('type t_rec_lab_test_info exists!');
end;
/
