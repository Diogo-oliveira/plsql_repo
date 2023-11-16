CREATE OR REPLACE TYPE t_obj_noc_scale force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 2/27/2014 4:21:10 PM
-- Purpose : NANDA, NIC, NOC development: Object type to represent NOC Likert Scale

-- Attributes
    id_noc_scale    NUMBER(24),
    scale_code      VARCHAR2(200 CHAR),
    desc_noc_scale  VARCHAR2(4000),
    lst_scale_level t_coll_obj_likert_scale_level,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_scale
    (
        SELF              IN OUT NOCOPY t_obj_noc_scale,
        i_id_noc_scale    IN NUMBER DEFAULT NULL,
        i_scale_code      IN VARCHAR2 DEFAULT NULL,
        i_desc_noc_scale  IN VARCHAR2 DEFAULT NULL,
        i_lst_scale_level IN t_coll_obj_likert_scale_level DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_noc_scale AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_noc_scale
    (
        SELF              IN OUT NOCOPY t_obj_noc_scale,
        i_id_noc_scale    IN NUMBER DEFAULT NULL,
        i_scale_code      IN VARCHAR2 DEFAULT NULL,
        i_desc_noc_scale  IN VARCHAR2 DEFAULT NULL,
        i_lst_scale_level IN t_coll_obj_likert_scale_level DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_noc_scale    := i_id_noc_scale;
        self.scale_code      := i_scale_code;
        self.desc_noc_scale  := i_desc_noc_scale;
        self.lst_scale_level := i_lst_scale_level;
        RETURN;
    END t_obj_noc_scale;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json     json_object_t;
        l_json_lst json_array_t;
    BEGIN
    
        l_json.put('ID_NOC_SCALE', self.id_noc_scale);
        l_json.put('SCALE_CODE', self.scale_code);
        l_json.put('DESC_NOC_SCALE', self.desc_noc_scale);
    
        IF self.lst_scale_level IS NOT empty
        THEN
            FOR i IN 1 .. self.lst_scale_level.count()
            LOOP
                l_json_lst.append(self.lst_scale_level(i).to_json());
            END LOOP;
        END IF;
        l_json.put('LST_SCALE_LEVEL', l_json_lst);
    
        RETURN l_json;
    END to_json;
END;
/
