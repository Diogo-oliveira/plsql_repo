CREATE OR REPLACE TYPE t_obj_status force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/31/2014 5:32:29 PM
-- Purpose : Object to represent the status of a record

-- Attributes
    flg_status      VARCHAR2(30 CHAR),
    desc_flg_status VARCHAR2(4000),
    icon            VARCHAR2(200 CHAR),
    status_string   VARCHAR2(500 CHAR),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_status
    (
        SELF              IN OUT NOCOPY t_obj_status,
        i_flg_status      IN VARCHAR2 DEFAULT NULL,
        i_desc_flg_status IN VARCHAR2 DEFAULT NULL,
        i_icon            IN VARCHAR2 DEFAULT NULL,
        i_status_string   IN VARCHAR2 DEFAULT NULL
        
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_status AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_status
    (
        SELF              IN OUT NOCOPY t_obj_status,
        i_flg_status      IN VARCHAR2 DEFAULT NULL,
        i_desc_flg_status IN VARCHAR2 DEFAULT NULL,
        i_icon            IN VARCHAR2 DEFAULT NULL,
        i_status_string   IN VARCHAR2 DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.flg_status      := i_flg_status;
        self.desc_flg_status := i_desc_flg_status;
        self.icon            := i_icon;
    
        RETURN;
    END t_obj_status;

    -- Member procedures and functions
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
    
        l_json.put('FLG_STATUS', self.flg_status);
        l_json.put('DESC_FLG_STATUS', self.desc_flg_status);
        l_json.put('ICON', self.icon);
        l_json.put('STATUS_STRING', self.status_string);
    
        RETURN l_json;
    END to_json;
END;
/
