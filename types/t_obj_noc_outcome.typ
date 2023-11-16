CREATE OR REPLACE TYPE t_obj_noc_outcome force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 2/27/2014 5:20:12 PM
-- Purpose : NANDA, NIC, NOC development: Object type to represent NOC Outcome

-- Attributes
    id_noc_outcome NUMBER(24),
    noc_code       NUMBER(24),
    name           VARCHAR2(4000),
    definition     VARCHAR2(4000),
    noc_scale      t_obj_noc_scale,
    references     CLOB,
    CLASS          t_obj_noc_class,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_outcome
    (
        SELF             IN OUT NOCOPY t_obj_noc_outcome,
        i_id_noc_outcome IN NUMBER DEFAULT NULL,
        i_noc_code       IN NUMBER DEFAULT NULL,
        i_name           IN VARCHAR2 DEFAULT NULL,
        i_definition     IN VARCHAR2 DEFAULT NULL,
        i_noc_scale      IN t_obj_noc_scale DEFAULT NULL,
        i_references     IN CLOB DEFAULT NULL,
        i_class          IN t_obj_noc_class DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_noc_outcome AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_outcome
    (
        SELF             IN OUT NOCOPY t_obj_noc_outcome,
        i_id_noc_outcome IN NUMBER DEFAULT NULL,
        i_noc_code       IN NUMBER DEFAULT NULL,
        i_name           IN VARCHAR2 DEFAULT NULL,
        i_definition     IN VARCHAR2 DEFAULT NULL,
        i_noc_scale      IN t_obj_noc_scale DEFAULT NULL,
        i_references     IN CLOB DEFAULT NULL,
        i_class          IN t_obj_noc_class DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_noc_outcome := i_id_noc_outcome;
        self.noc_code       := i_noc_code;
        self.name           := i_name;
        self.definition     := i_definition;
        self.noc_scale      := i_noc_scale;
        self.references     := i_references;
        self.class          := i_class;
        RETURN;
    END t_obj_noc_outcome;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json.put('ID_NOC_OUTCOME', self.id_noc_outcome);
        l_json.put('NOC_CODE', self.noc_code);
        l_json.put('NAME', self.name);
        l_json.put('DEFINITION', self.definition);
        IF self.noc_scale IS NOT NULL
        THEN
            l_json.put('NOC_SCALE', self.noc_scale.to_json());
        ELSE
            l_json.put('NOC_SCALE', json_object_t());
        END IF;
        l_json.put('REFERENCES', self.references);
        IF self.class IS NOT NULL
        THEN
            l_json.put('CLASS', self.class.to_json());
        ELSE
            l_json.put('CLASS', json_object_t());
        END IF;
    
        RETURN l_json;
    END to_json;
END;
/
