CREATE OR REPLACE TYPE t_rec_param_prop_val AS OBJECT
(
    id_rcm_rule    NUMBER(24),
    parameter_name VARCHAR2(100 CHAR),
    id_instance    NUMBER(24),
    id_institution NUMBER(24),
    id_prop        NUMBER(24),
    chr_val        VARCHAR2(500 CHAR),
    num_val        NUMBER(24),
    dte_val        TIMESTAMP
        WITH LOCAL TIME ZONE,
    interval_val   INTERVAL YEAR TO MONTH,

    CONSTRUCTOR FUNCTION t_rec_param_prop_val RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_param_prop_val IS
    CONSTRUCTOR FUNCTION t_rec_param_prop_val RETURN SELF AS RESULT IS
    BEGIN
        self.id_rcm_rule    := NULL;
        self.parameter_name := NULL;
        self.id_instance    := NULL;
        self.id_institution := NULL;
        self.id_prop        := NULL;
        self.chr_val        := NULL;
        self.num_val        := NULL;
        self.dte_val        := NULL;
        self.interval_val   := NULL;
    
        RETURN;
    END;
END;
/