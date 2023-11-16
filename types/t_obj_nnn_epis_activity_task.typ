CREATE OR REPLACE TYPE t_obj_nnn_epis_activity_task force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 10/9/2014 2:22:09 PM
-- Purpose : NANDA, NIC, NOC development: Object type to represent an activity task on the execution of NIC Activity

-- Attributes
    id_nic_activity NUMBER(24),
    activity_name   VARCHAR2(4000),
    flg_executed    VARCHAR2(1 CHAR),
    notes           CLOB,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_activity_task
    (
        SELF              IN OUT NOCOPY t_obj_nnn_epis_activity_task,
        i_id_nic_activity IN NUMBER DEFAULT NULL,
        i_activity_name   IN VARCHAR2 DEFAULT NULL,
        i_flg_executed    IN VARCHAR2 DEFAULT NULL,
        i_notes           IN CLOB DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_nnn_epis_activity_task AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_activity_task
    (
        SELF              IN OUT NOCOPY t_obj_nnn_epis_activity_task,
        i_id_nic_activity IN NUMBER DEFAULT NULL,
        i_activity_name   IN VARCHAR2 DEFAULT NULL,
        i_flg_executed    IN VARCHAR2 DEFAULT NULL,
        i_notes           IN CLOB DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nic_activity := i_id_nic_activity;
        self.activity_name   := i_activity_name;
        self.flg_executed    := i_flg_executed;
        self.notes           := i_notes;
        RETURN;
    END t_obj_nnn_epis_activity_task;

    -- Member procedures and functions
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json  json_object_t;
        l_notes json_object_t;
    BEGIN
    
        l_json.put('ID_NIC_ACTIVITY', self.id_nic_activity);
        l_json.put('ACTIVITY_NAME', self.activity_name);
        l_json.put('FLG_EXECUTED', self.flg_executed);
        l_notes := json_object_t.parse(self.notes);
        l_json.put('NOTES', l_notes);
        RETURN l_json;
    END to_json;
END;
/
