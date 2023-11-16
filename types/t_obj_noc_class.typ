CREATE OR REPLACE TYPE t_obj_noc_class force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 2/27/2014 5:05:10 PM
-- Purpose : NANDA, NIC, NOC development: Object type to represent NOC Class

-- Attributes
    id_noc_class NUMBER(24),
    class_code   VARCHAR2(200 CHAR),
    name         VARCHAR2(4000),
    definition   VARCHAR2(4000),
    domain       t_obj_noc_domain,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_class
    (
        SELF           IN OUT NOCOPY t_obj_noc_class,
        i_id_noc_class IN NUMBER DEFAULT NULL,
        i_class_code   IN VARCHAR2 DEFAULT NULL,
        i_name         IN VARCHAR2 DEFAULT NULL,
        i_definition   IN VARCHAR2 DEFAULT NULL,
        i_domain       IN t_obj_noc_domain DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_noc_class AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_class
    (
        SELF           IN OUT NOCOPY t_obj_noc_class,
        i_id_noc_class IN NUMBER DEFAULT NULL,
        i_class_code   IN VARCHAR2 DEFAULT NULL,
        i_name         IN VARCHAR2 DEFAULT NULL,
        i_definition   IN VARCHAR2 DEFAULT NULL,
        i_domain       IN t_obj_noc_domain DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_noc_class := i_id_noc_class;
        self.class_code   := i_class_code;
        self.name         := i_name;
        self.definition   := i_definition;
        self.domain       := i_domain;
        RETURN;
    END t_obj_noc_class;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
    
        l_json.put('ID_NOC_CLASS', self.id_noc_class);
        l_json.put('CLASS_CODE', self.class_code);
        l_json.put('NAME', self.name);
        l_json.put('DEFINITION', self.definition);
        IF self.domain IS NOT NULL
        THEN
            l_json.put('DOMAIN', self.domain.to_json());
        ELSE
            l_json.put('DOMAIN', json_object_t());
        END IF;
    
        RETURN l_json;
    END to_json;
END;
/
