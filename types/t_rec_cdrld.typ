CREATE OR REPLACE TYPE t_rec_cdrld FORCE AS OBJECT
(
-- represents a row in cdr_call_det
    id_cdr_inst_param NUMBER(24), -- rule instance parameter identifier
    id_cdr_instance   NUMBER(24), -- rule instance identifier
    id_task_type      NUMBER(24), -- task type identifier
    id_task_request   VARCHAR2(255 CHAR), -- task request identifier
    param_value       VARCHAR2(200 CHAR), -- rule instance parameter valuation

    CONSTRUCTOR FUNCTION t_rec_cdrld
    (
        id_cdr_inst_param IN NUMBER := NULL,
        id_cdr_instance   IN NUMBER := NULL,
        id_task_type      IN NUMBER := NULL,
        id_task_request   IN VARCHAR2 := NULL,
        param_value       IN VARCHAR2 := NULL
    ) RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY t_rec_cdrld IS

    CONSTRUCTOR FUNCTION t_rec_cdrld
    (
        id_cdr_inst_param IN NUMBER := NULL,
        id_cdr_instance   IN NUMBER := NULL,
        id_task_type      IN NUMBER := NULL,
        id_task_request   IN VARCHAR2 := NULL,
        param_value       IN VARCHAR2 := NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_cdr_inst_param := id_cdr_inst_param;
        self.id_cdr_instance   := id_cdr_instance;
        self.id_task_type      := id_task_type;
        self.id_task_request   := id_task_request;
        self.param_value       := param_value;
    
        RETURN;
    END;

END;
/
