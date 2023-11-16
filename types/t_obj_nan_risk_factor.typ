CREATE OR REPLACE TYPE t_obj_nan_risk_factor force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/27/2014 10:24:11 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent Risk factors for NANDA nursing diagnoses

-- Attributes
    id_nan_risk_factor NUMBER(24),
    description        VARCHAR2(4000),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nan_risk_factor
    (
        SELF                 IN OUT NOCOPY t_obj_nan_risk_factor,
        i_id_nan_risk_factor IN NUMBER DEFAULT NULL,
        i_description        IN VARCHAR2 DEFAULT NULL
        
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_nan_risk_factor AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nan_risk_factor
    (
        SELF                 IN OUT NOCOPY t_obj_nan_risk_factor,
        i_id_nan_risk_factor IN NUMBER DEFAULT NULL,
        i_description        IN VARCHAR2 DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nan_risk_factor := i_id_nan_risk_factor;
        self.description        := i_description;
    
        RETURN;
    END t_obj_nan_risk_factor;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json.put('ID_NAN_RISK_FACTOR', self.id_nan_risk_factor);
        l_json.put('DESCRIPTION', self.description);
        RETURN l_json;
    END to_json;
END;
/
