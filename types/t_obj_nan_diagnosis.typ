CREATE OR REPLACE TYPE t_obj_nan_diagnosis force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/27/2014 10:16:08 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent NANDA Diagnosis

-- Attributes
    id_nan_diagnosis NUMBER(24),
    nanda_code       NUMBER(24),
    name             VARCHAR2(4000),
    definition       VARCHAR2(4000),
    year_approved    VARCHAR2(4 CHAR),
    year_revised     VARCHAR2(4 CHAR),
    loe              VARCHAR2(3 CHAR),
    references       CLOB,
    CLASS            t_obj_nan_class,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nan_diagnosis
    (
        SELF               IN OUT NOCOPY t_obj_nan_diagnosis,
        i_id_nan_diagnosis IN NUMBER DEFAULT NULL,
        i_nanda_code       IN NUMBER DEFAULT NULL,
        i_name             IN VARCHAR2 DEFAULT NULL,
        i_definition       IN VARCHAR2 DEFAULT NULL,
        i_year_approved    IN VARCHAR2 DEFAULT NULL,
        i_year_revised     IN VARCHAR2 DEFAULT NULL,
        i_loe              IN VARCHAR2 DEFAULT NULL,
        i_references       IN CLOB DEFAULT NULL,
        i_class            IN t_obj_nan_class DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_nan_diagnosis AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nan_diagnosis
    (
        SELF               IN OUT NOCOPY t_obj_nan_diagnosis,
        i_id_nan_diagnosis IN NUMBER DEFAULT NULL,
        i_nanda_code       IN NUMBER DEFAULT NULL,
        i_name             IN VARCHAR2 DEFAULT NULL,
        i_definition       IN VARCHAR2 DEFAULT NULL,
        i_year_approved    IN VARCHAR2 DEFAULT NULL,
        i_year_revised     IN VARCHAR2 DEFAULT NULL,
        i_loe              IN VARCHAR2 DEFAULT NULL,
        i_references       IN CLOB DEFAULT NULL,
        i_class            IN t_obj_nan_class DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nan_diagnosis := i_id_nan_diagnosis;
        self.nanda_code       := i_nanda_code;
        self.name             := i_name;
        self.definition       := i_definition;
        self.year_approved    := i_year_approved;
        self.year_revised     := i_year_revised;
        self.loe              := i_loe;
        self.references       := i_references;
        self.class            := i_class;
        RETURN;
    END t_obj_nan_diagnosis;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json.put('ID_NAN_DIAGNOSIS', self.id_nan_diagnosis);
        l_json.put('NANDA_CODE', self.nanda_code);
        l_json.put('NAME', self.name);
        l_json.put('DEFINITION', self.definition);
        l_json.put('YEAR_APPROVED', self.year_approved);
        l_json.put('YEAR_REVISED', self.year_revised);
        l_json.put('LOE', self.loe);
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
