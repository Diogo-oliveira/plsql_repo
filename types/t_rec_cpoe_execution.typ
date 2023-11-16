CREATE OR REPLACE TYPE t_rec_cpoe_execution force AS OBJECT
(
    id_task_type    NUMBER(24), -- used only by CPOE
    id_prescription NUMBER(24),
    planned_date    VARCHAR2(50 CHAR),
    exec_date       VARCHAR2(50 CHAR),
    exec_notes      VARCHAR2(1000 CHAR),
    out_of_period   VARCHAR2(1 CHAR),
    CONSTRUCTOR FUNCTION t_rec_cpoe_execution RETURN SELF AS RESULT,
    MEMBER FUNCTION to_string RETURN VARCHAR2
);
/
CREATE OR REPLACE TYPE BODY t_rec_cpoe_execution IS

    CONSTRUCTOR FUNCTION t_rec_cpoe_execution RETURN SELF AS RESULT IS
    BEGIN
        self.id_task_type    := NULL;
        self.id_prescription := NULL;
        self.planned_date    := NULL;
        self.exec_date       := NULL;
        self.exec_notes      := NULL;
        self.out_of_period   := NULL;
    
        RETURN;
    END;

    MEMBER FUNCTION to_string RETURN VARCHAR2 IS
    BEGIN
        RETURN 'ORDERS';
    END to_string;
END;
/
