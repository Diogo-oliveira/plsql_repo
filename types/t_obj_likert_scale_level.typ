CREATE OR REPLACE TYPE t_obj_likert_scale_level force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/31/2014 5:52:27 PM
-- Purpose : Value of a Likert Scale

-- Attributes
    scale_level_value      NUMBER(24),
    desc_scale_level_value VARCHAR2(4000),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_likert_scale_level
    (
        SELF                     IN OUT NOCOPY t_obj_likert_scale_level,
        i_scale_level_value      IN NUMBER DEFAULT NULL,
        i_desc_scale_level_value IN VARCHAR2 DEFAULT NULL
        
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_likert_scale_level AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_likert_scale_level
    (
        SELF                     IN OUT NOCOPY t_obj_likert_scale_level,
        i_scale_level_value      IN NUMBER DEFAULT NULL,
        i_desc_scale_level_value IN VARCHAR2 DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.scale_level_value      := i_scale_level_value;
        self.desc_scale_level_value := i_desc_scale_level_value;
    
        RETURN;
    END t_obj_likert_scale_level;

    -- Member procedures and functions
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
    
        l_json.put('SCALE_LEVEL_VALUE', self.scale_level_value);
        l_json.put('DESC_SCALE_LEVEL_VALUE', self.desc_scale_level_value);
    
        RETURN l_json;
    END to_json;
END;
/
