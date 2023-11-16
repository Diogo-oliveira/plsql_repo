-- CHANGED BY: Alexandre Santos 
-- CHANGE DATE: 28-02-2014
-- CHANGE REASON: ALERT-277769 - PERFORMANCE - Most frequent and searchable diagnoses
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || replace(SRCSTR => SQLERRM, OLDSUB => 'ORA-', NEWSUB => '') || '; ' || i_sql || ';');
    END run_ddl;
BEGIN
    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_table_diag_cnt AS TABLE OF t_rec_diag_cnt');
END;
/
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Alexandre Santos 
-- CHANGE DATE: 23-07-2014
-- CHANGE REASON: ALERT-283853 - The system must provide the ability to select multiple problems for documentation simultaneously
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || replace(SRCSTR => SQLERRM, OLDSUB => 'ORA-', NEWSUB => '') || '; ' || i_sql || ';');
    END run_ddl;
BEGIN
--pk_versioning.run( i_sql);
    run_ddl(i_sql => 'DROP TYPE t_table_diag_cnt');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_rec_diag_cnt AS OBJECT
(
    id_diagnosis            NUMBER(24),
    id_diagnosis_parent     NUMBER(24),
    id_alert_diagnosis      NUMBER(24),
    code_icd                VARCHAR2(200 CHAR),
    id_language             NUMBER(24),
    code_translation        VARCHAR2(200 CHAR),
    desc_translation        VARCHAR2(1000 CHAR),
    flg_other               VARCHAR2(1 CHAR),
    flg_icd9                VARCHAR2(30 CHAR),
    flg_select              VARCHAR2(1 CHAR),
    id_dep_clin_serv        NUMBER(24),
    flg_terminology         VARCHAR(200 CHAR),
    rank                    NUMBER(24),
    id_term_task_type       NUMBER(24),
    flg_show_term_code      VARCHAR2(1 CHAR)
)');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_table_diag_cnt AS TABLE OF t_rec_diag_cnt');
END;
/
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Alexandre Santos 
-- CHANGE DATE: 25-07-2014
-- CHANGE REASON: ALERT-291510 - PH/Problems - Label 'with previous records' and filter patient diagnoses data doesn't appear automatically
DROP TYPE t_table_diag_cnt;

CREATE OR REPLACE TYPE t_rec_diag_cnt AS OBJECT
(
    id_diagnosis            NUMBER(24),
    id_diagnosis_parent     NUMBER(24),
    id_alert_diagnosis      NUMBER(24),
    code_icd                VARCHAR2(200 CHAR),
    id_language             NUMBER(24),
    code_translation        VARCHAR2(200 CHAR),
    desc_translation        VARCHAR2(1000 CHAR),
    desc_epis_diagnosis     VARCHAR2(1000 CHAR),
    flg_other               VARCHAR2(1 CHAR),
    flg_icd9                VARCHAR2(30 CHAR),
    flg_select              VARCHAR2(1 CHAR),
    id_dep_clin_serv        NUMBER(24),
    flg_terminology         VARCHAR(200 CHAR),
    rank                    NUMBER(24),
    id_term_task_type       NUMBER(24),
    flg_show_term_code      VARCHAR2(1 CHAR),
    CONSTRUCTOR FUNCTION t_rec_diag_cnt
    (
        SELF                   IN OUT NOCOPY t_rec_diag_cnt,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_alert_diagnosis      NUMBER,
        code_icd                VARCHAR2,
        id_language             NUMBER,
        code_translation        VARCHAR2,
        desc_translation        VARCHAR2,
        desc_epis_diagnosis     VARCHAR2,
        flg_other               VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_select              VARCHAR2,
        id_dep_clin_serv        NUMBER,
        flg_terminology         VARCHAR,
        rank                    NUMBER,
        id_term_task_type       NUMBER,
        flg_show_term_code      VARCHAR2
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_diag_cnt
    (
        SELF                   IN OUT NOCOPY t_rec_diag_cnt,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_alert_diagnosis      NUMBER,
        code_icd                VARCHAR2,
        id_language             NUMBER,
        code_translation        VARCHAR2,
        desc_translation        VARCHAR2,
        flg_other               VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_select              VARCHAR2,
        id_dep_clin_serv        NUMBER,
        flg_terminology         VARCHAR,
        rank                    NUMBER,
        id_term_task_type       NUMBER,
        flg_show_term_code      VARCHAR2
    ) RETURN SELF AS RESULT
) INSTANTIABLE
NOT FINAL;
/

CREATE OR REPLACE TYPE BODY t_rec_diag_cnt AS
    CONSTRUCTOR FUNCTION t_rec_diag_cnt
    (
        SELF                   IN OUT NOCOPY t_rec_diag_cnt,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_alert_diagnosis      NUMBER,
        code_icd                VARCHAR2,
        id_language             NUMBER,
        code_translation        VARCHAR2,
        desc_translation        VARCHAR2,
        desc_epis_diagnosis     VARCHAR2,
        flg_other               VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_select              VARCHAR2,
        id_dep_clin_serv        NUMBER,
        flg_terminology         VARCHAR,
        rank                    NUMBER,
        id_term_task_type       NUMBER,
        flg_show_term_code      VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_diagnosis        := id_diagnosis;
        self.id_diagnosis_parent := id_diagnosis_parent;
        self.id_alert_diagnosis  := id_alert_diagnosis;
        self.code_icd            := code_icd;
        self.id_language         := id_language;
        self.code_translation    := code_translation;
        self.desc_translation    := desc_translation;
        self.desc_epis_diagnosis := desc_epis_diagnosis;
        self.flg_other           := flg_other;
        self.flg_icd9            := flg_icd9;
        self.flg_select          := flg_select;
        self.id_dep_clin_serv    := id_dep_clin_serv;
        self.flg_terminology     := flg_terminology;
        self.rank                := rank;
        self.id_term_task_type   := id_term_task_type;
        self.flg_show_term_code  := flg_show_term_code;
    
        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_diag_cnt
    (
        SELF                   IN OUT NOCOPY t_rec_diag_cnt,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_alert_diagnosis      NUMBER,
        code_icd                VARCHAR2,
        id_language             NUMBER,
        code_translation        VARCHAR2,
        desc_translation        VARCHAR2,
        flg_other               VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_select              VARCHAR2,
        id_dep_clin_serv        NUMBER,
        flg_terminology         VARCHAR,
        rank                    NUMBER,
        id_term_task_type       NUMBER,
        flg_show_term_code      VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_diagnosis        := id_diagnosis;
        self.id_diagnosis_parent := id_diagnosis_parent;
        self.id_alert_diagnosis  := id_alert_diagnosis;
        self.code_icd            := code_icd;
        self.id_language         := id_language;
        self.code_translation    := code_translation;
        self.desc_translation    := desc_translation;
        self.desc_epis_diagnosis := NULL;
        self.flg_other           := flg_other;
        self.flg_icd9            := flg_icd9;
        self.flg_select          := flg_select;
        self.id_dep_clin_serv    := id_dep_clin_serv;
        self.flg_terminology     := flg_terminology;
        self.rank                := rank;
        self.id_term_task_type   := id_term_task_type;
        self.flg_show_term_code  := flg_show_term_code;
    
        RETURN;
    END;
END;
/

CREATE OR REPLACE TYPE t_table_diag_cnt AS TABLE OF t_rec_diag_cnt;


-- CHANGED BY: Alexandre Santos 
-- CHANGE DATE: 29-07-2014
-- CHANGE REASON: ALERT-291949 - Performance - All filter is too slow
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || replace(SRCSTR => SQLERRM, OLDSUB => 'ORA-', NEWSUB => '') || '; ' || i_sql || ';');
    END run_ddl;
BEGIN
    run_ddl(i_sql => 'DROP TYPE t_table_diag_cnt');

    run_ddl(i_sql => 'DROP TYPE BODY t_rec_diag_cnt');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_rec_diag_cnt AS OBJECT
(
    id_diagnosis            NUMBER(24),
    id_diagnosis_parent     NUMBER(24),
    id_alert_diagnosis      NUMBER(24),
    code_icd                VARCHAR2(200 CHAR),
    id_language             NUMBER(24),
    code_translation        VARCHAR2(200 CHAR),
    desc_translation        VARCHAR2(1000 CHAR),
    desc_epis_diagnosis     VARCHAR2(1000 CHAR),
    flg_other               VARCHAR2(1 CHAR),
    flg_icd9                VARCHAR2(30 CHAR),
    flg_select              VARCHAR2(1 CHAR),
    id_dep_clin_serv        NUMBER(24),
    flg_terminology         VARCHAR(200 CHAR),
    rank                    NUMBER(24),
    id_term_task_type       NUMBER(24),
    flg_show_term_code      VARCHAR2(1 CHAR)
)');

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_table_diag_cnt AS TABLE OF t_rec_diag_cnt');
END;
/
-- CHANGE END: Alexandre Santos
/
-- CHANGE END: Alexandre Santos
