CREATE OR REPLACE TYPE t_obj_nan_domain force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/27/2014 9:58:09 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent NANDA Domain

-- Attributes
    id_nan_domain NUMBER(24),
    domain_code   VARCHAR2(200 CHAR),
    name          VARCHAR2(4000),
    definition    VARCHAR2(4000),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nan_domain
    (
        SELF            IN OUT NOCOPY t_obj_nan_domain,
        i_id_nan_domain IN NUMBER DEFAULT NULL,
        i_domain_code   IN VARCHAR2 DEFAULT NULL,
        i_name          IN VARCHAR2 DEFAULT NULL,
        i_definition    IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_nan_domain AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nan_domain
    (
        SELF            IN OUT NOCOPY t_obj_nan_domain,
        i_id_nan_domain IN NUMBER DEFAULT NULL,
        i_domain_code   IN VARCHAR2 DEFAULT NULL,
        i_name          IN VARCHAR2 DEFAULT NULL,
        i_definition    IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nan_domain := i_id_nan_domain;
        self.domain_code   := i_domain_code;
        self.name          := i_name;
        self.definition    := i_definition;
        RETURN;
    END t_obj_nan_domain;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json.put('ID_NAN_DOMAIN', self.id_nan_domain);
        l_json.put('DOMAIN_CODE', self.domain_code);
        l_json.put('NAME', self.name);
        l_json.put('DEFINITION', self.definition);
        RETURN l_json;
    END to_json;
END;
/
