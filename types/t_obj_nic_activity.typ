CREATE OR REPLACE TYPE t_obj_nic_activity force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 3/3/2014 11:35:23 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent NIC Activity

-- Attributes
    id_nic_activity      NUMBER(24),
    description          VARCHAR2(4000),
    interv_activity_code VARCHAR(200 CHAR),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nic_activity
    (
        SELF                   IN OUT NOCOPY t_obj_nic_activity,
        i_id_nic_activity      IN NUMBER DEFAULT NULL,
        i_description          IN VARCHAR2 DEFAULT NULL,
        i_interv_activity_code IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_nic_activity AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nic_activity
    (
        SELF                   IN OUT NOCOPY t_obj_nic_activity,
        i_id_nic_activity      IN NUMBER DEFAULT NULL,
        i_description          IN VARCHAR2 DEFAULT NULL,
        i_interv_activity_code IN VARCHAR2 DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nic_activity      := i_id_nic_activity;
        self.description          := i_description;
        self.interv_activity_code := i_interv_activity_code;
        RETURN;
    END t_obj_nic_activity;

    -- Member procedures and functions
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
    
        l_json.put('ID_NIC_ACTIVITY', self.id_nic_activity);
        l_json.put('DESCRIPTION', self.description);
        l_json.put('INTERV_ACTIVITY_CODE', self.interv_activity_code);
    
        RETURN l_json;
    END to_json;
END;
/
