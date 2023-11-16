CREATE OR REPLACE TYPE t_rec_po_value force AS OBJECT
(
-- represents a periodic observation value
    id_po_param       NUMBER(24), -- periodic observation parameter identifier
    id_inst_owner     NUMBER(24), -- owner institution identifier
    id_result         NUMBER(24), -- local result identifier
    id_episode        NUMBER(24), -- result registration episode
    id_institution    NUMBER(24), -- result registration institution
    id_software       NUMBER(24), -- result registration software
    id_prof_reg       NUMBER(24), -- professional who registered result
    dt_result         TIMESTAMP
        WITH LOCAL TIME ZONE, -- result date
    dt_result_aggr    TIMESTAMP
        WITH LOCAL TIME ZONE, -- aggregated result date
    dt_reg            TIMESTAMP
        WITH LOCAL TIME ZONE, -- registration date
    flg_status        VARCHAR2(1 CHAR), -- result status: (A)ctive, (C)anceled
    desc_result       clob, -- result description
    desc_unit_measure VARCHAR2(1000 CHAR), -- result measurement unit description
    icon              VARCHAR2(200 CHAR), -- result icon
    lab_param_count   NUMBER(3, 0), -- lab test result parameter count
    lab_param_id      NUMBER(24), -- lab test parameter identifier (ANALYSIS_PARAMETER)
    lab_param_rank    NUMBER(24), -- lab test parameter rank
    val_min           VARCHAR2(200 CHAR), -- minimum reference value
    val_max           VARCHAR2(200 CHAR), -- maximum reference value
    abnorm_value      VARCHAR2(200 CHAR), -- result abnormality value
    option_codes      table_varchar, -- result multichoice option codes
    flg_cancel        VARCHAR2(1 CHAR), -- value cancelable? Y/N
    dt_cancel         TIMESTAMP
        WITH LOCAL TIME ZONE, -- result cancelation date
    id_prof_cancel    NUMBER(24), -- professional who canceled result
    id_cancel_reason  NUMBER(24), -- cancelation reason
    notes_cancel      clob, -- result cancelation notes
    woman_health_id   VARCHAR2(50 CHAR), -- WOMAN_HEALTH indentifier
    flg_ref_value     VARCHAR2(1 CHAR), -- WOMAN_HEALTH indentifier
    dt_harvest        TIMESTAMP
        WITH LOCAL TIME ZONE,
    dt_execution      TIMESTAMP
        WITH LOCAL TIME ZONE,
    notes      clob,
    id_sample_type    NUMBER(12),
    CONSTRUCTOR FUNCTION t_rec_po_value RETURN SELF AS RESULT,

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2,
    MEMBER FUNCTION get_opt_count RETURN NUMBER,
    MEMBER FUNCTION get_opt_code_first RETURN VARCHAR2,

    PRAGMA RESTRICT_REFERENCES(DEFAULT, WNDS, WNPS, RNPS, RNDS)

)
/
CREATE OR REPLACE TYPE BODY t_rec_po_value IS

    CONSTRUCTOR FUNCTION t_rec_po_value RETURN SELF AS RESULT IS
    BEGIN
        self.id_po_param       := NULL;
        self.id_inst_owner     := NULL;
        self.id_result         := NULL;
        self.id_episode        := NULL;
        self.id_institution    := NULL;
        self.id_software       := NULL;
        self.id_prof_reg       := NULL;
        self.dt_result         := NULL;
        self.dt_result_aggr    := NULL;
        self.dt_reg            := NULL;
        self.flg_status        := NULL;
        self.desc_result       := NULL;
        self.desc_unit_measure := NULL;
        self.icon              := NULL;
        self.lab_param_count   := NULL;
        self.lab_param_id      := NULL;
        self.lab_param_rank    := NULL;
        self.val_min           := NULL;
        self.val_max           := NULL;
        self.abnorm_value      := NULL;
        self.option_codes      := table_varchar();
        self.flg_cancel        := NULL;
        self.dt_cancel         := NULL;
        self.id_prof_cancel    := NULL;
        self.id_cancel_reason  := NULL;
        self.notes_cancel      := NULL;
        self.woman_health_id   := NULL;
        self.flg_ref_value     := NULL;
        self.dt_harvest        := NULL;
        self.dt_execution      := NULL;
        self.notes             := NULL;
        self.id_sample_type    := NULL;
    
        RETURN;
    END;

    MAP MEMBER FUNCTION get_key RETURN VARCHAR2 IS
    BEGIN
        RETURN to_char(self.id_inst_owner) || lpad(self.id_po_param, 24, '0') || lpad(self.id_result, 24, '0') || lpad(self.lab_param_id,
                                                                                                                       24,
                                                                                                                       '0');
    END;

    MEMBER FUNCTION get_opt_count RETURN NUMBER IS
        l_ret NUMBER;
    BEGIN
        IF self.option_codes IS NULL
        THEN
            l_ret := 0;
        ELSE
            l_ret := self.option_codes.count;
        END IF;
    
        RETURN l_ret;
    END;

    MEMBER FUNCTION get_opt_code_first RETURN VARCHAR2 IS
        l_ret VARCHAR2(200 CHAR);
    BEGIN
        IF get_opt_count() > 0
        THEN
            l_ret := self.option_codes(self.option_codes.first);
        ELSE
            l_ret := NULL;
        END IF;
    
        RETURN l_ret;
    END;

END;
/
