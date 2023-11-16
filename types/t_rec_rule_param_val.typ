CREATE OR REPLACE TYPE t_rec_rule_param_val AS OBJECT
(
    id_rcm_rule        NUMBER(24),
    id_rule_inst       NUMBER(24),
    parameter_name     VARCHAR2(100 CHAR),
    id_param_seq       NUMBER(24),
    chr_val            VARCHAR2(500 CHAR),
    num_val            NUMBER(24),
    dte_val            TIMESTAMP
        WITH LOCAL TIME ZONE,
    interval_val       INTERVAL YEAR(2) TO MONTH,
    rank               NUMBER(24),
    parameter_name_par VARCHAR2(100 CHAR),
    id_institution     NUMBER(24),

    CONSTRUCTOR FUNCTION t_rec_rule_param_val RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_rule_param_val IS
    CONSTRUCTOR FUNCTION t_rec_rule_param_val RETURN SELF AS RESULT IS
    BEGIN
        self.id_rcm_rule        := NULL;
        self.id_rule_inst       := NULL;
        self.parameter_name     := NULL;
        self.id_param_seq       := NULL;
        self.chr_val            := NULL;
        self.num_val            := NULL;
        self.dte_val            := NULL;
        self.interval_val       := NULL;
        self.rank               := NULL;
        self.parameter_name_par := NULL;
        self.id_institution     := NULL;
    
        RETURN;
    END;
END;
/