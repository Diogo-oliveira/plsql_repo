CREATE OR REPLACE TYPE t_obj_noc_indicator force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 2/28/2014 11:55:11 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent a NOC indicator

-- Attributes
    id_noc_indicator       NUMBER(24),
    description            VARCHAR2(4000),
    flg_other              VARCHAR2(4000),
    outcome_indicator_code NUMBER(24),
    noc_scale              t_obj_noc_scale,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_indicator
    (
        SELF                     IN OUT NOCOPY t_obj_noc_indicator,
        i_id_noc_indicator       IN NUMBER DEFAULT NULL,
        i_description            IN VARCHAR2 DEFAULT NULL,
        i_flg_other              IN VARCHAR2 DEFAULT NULL,
        i_outcome_indicator_code IN NUMBER DEFAULT NULL,
        i_noc_scale              IN t_obj_noc_scale DEFAULT NULL
        
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_noc_indicator AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_indicator
    (
        SELF                     IN OUT NOCOPY t_obj_noc_indicator,
        i_id_noc_indicator       IN NUMBER DEFAULT NULL,
        i_description            IN VARCHAR2 DEFAULT NULL,
        i_flg_other              IN VARCHAR2 DEFAULT NULL,
        i_outcome_indicator_code IN NUMBER DEFAULT NULL,
        i_noc_scale              IN t_obj_noc_scale DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_noc_indicator       := i_id_noc_indicator;
        self.description            := i_description;
        self.flg_other              := i_flg_other;
        self.outcome_indicator_code := i_outcome_indicator_code;
        self.noc_scale              := i_noc_scale;
    
        RETURN;
    END t_obj_noc_indicator;

    -- Member procedures and functions
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
    
        l_json.put('ID_NOC_INDICATOR', self.id_noc_indicator);
        l_json.put('DESCRIPTION', self.description);
        l_json.put('FLG_OTHER', self.flg_other);
        l_json.put('OUTCOME_INDICATOR_CODE', self.outcome_indicator_code);
        IF self.noc_scale IS NOT NULL
        THEN
            l_json.put('NOC_SCALE', self.noc_scale.to_json());
        ELSE
            l_json.put('NOC_SCALE', json_object_t());
        END IF;
    
        RETURN l_json;
    END to_json;
END;
/
