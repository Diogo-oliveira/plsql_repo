CREATE OR REPLACE TYPE t_obj_prof_info force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/30/2014 16:28:08 AM
-- Purpose : Object type to represent a professional and his signature in the context of a record

-- Attributes
    id_professional NUMBER(24),
    nick_name       VARCHAR2(1000 CHAR),
    desc_speciality VARCHAR2(1000 CHAR),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_prof_info
    (
        SELF              IN OUT NOCOPY t_obj_prof_info,
        i_id_professional IN NUMBER DEFAULT NULL,
        i_nick_name       IN VARCHAR2 DEFAULT NULL,
        i_desc_speciality IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_prof_info AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_prof_info
    (
        SELF              IN OUT NOCOPY t_obj_prof_info,
        i_id_professional IN NUMBER DEFAULT NULL,
        i_nick_name       IN VARCHAR2 DEFAULT NULL,
        i_desc_speciality IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_professional := i_id_professional;
        self.nick_name       := i_nick_name;
        self.desc_speciality := i_desc_speciality;
        RETURN;
    END t_obj_prof_info;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
    
        l_json.put('ID_PROFESSIONAL', self.id_professional);
        l_json.put('NICK_NAME', self.nick_name);
        l_json.put('DESC_SPECIALITY', self.desc_speciality);
        RETURN l_json;
    END to_json;
END;
/
