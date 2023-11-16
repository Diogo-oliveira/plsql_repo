BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_tab_pat_education_rec AS TABLE OF t_rec_pat_education_rec';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/