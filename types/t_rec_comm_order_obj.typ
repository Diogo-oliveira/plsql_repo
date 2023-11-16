-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2014-APR-17
-- CHANGED REASON: ALERT-275664
CREATE OR REPLACE TYPE t_rec_comm_order_obj AS OBJECT
(
    id_comm_order         number(24),
    id_comm_order_type    NUMBER(24),

    CONSTRUCTOR FUNCTION t_rec_comm_order_obj RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_comm_order_obj IS
    CONSTRUCTOR FUNCTION t_rec_comm_order_obj RETURN SELF AS RESULT IS
    BEGIN

        self.id_comm_order      := NULL;
        self.id_comm_order_type := NULL;

        RETURN;
    END;
END;
/
-- CHANGE END: Ana Monteiro