CREATE OR REPLACE TYPE t_obj_nic_activity_supply force AS OBJECT
(
-- Author  : CRISTINA.OLIVEIRA
-- Created : 09-04-2014 14:10:28
-- Purpose : Object type to return the default supplies associated to activities

-- Attributes
    id_context          VARCHAR2(100 CHAR),
    id_supply           NUMBER(24),
    id_supply_set       NUMBER(24),
    id_supply_soft_inst NUMBER(24),
    desc_supply         VARCHAR2(4000),
    desc_supply_set     VARCHAR2(4000),
    quantity            NUMBER(10, 3),
    dt_return           TIMESTAMP WITH LOCAL TIME ZONE,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nic_activity_supply
    (
        SELF                  IN OUT NOCOPY t_obj_nic_activity_supply,
        i_id_context          IN VARCHAR2 DEFAULT NULL,
        i_id_supply           IN NUMBER DEFAULT NULL,
        i_id_supply_set       IN NUMBER DEFAULT NULL,
        i_id_supply_soft_inst IN NUMBER DEFAULT NULL,
        i_desc_supply         IN VARCHAR2 DEFAULT NULL,
        i_desc_supply_set     IN VARCHAR2 DEFAULT NULL,
        i_quantity            IN NUMBER DEFAULT NULL,
        i_dt_return           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_nic_activity_supply AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nic_activity_supply
    (
        SELF                  IN OUT NOCOPY t_obj_nic_activity_supply,
        i_id_context          IN VARCHAR2 DEFAULT NULL,
        i_id_supply           IN NUMBER DEFAULT NULL,
        i_id_supply_set       IN NUMBER DEFAULT NULL,
        i_id_supply_soft_inst IN NUMBER DEFAULT NULL,
        i_desc_supply         IN VARCHAR2 DEFAULT NULL,
        i_desc_supply_set     IN VARCHAR2 DEFAULT NULL,
        i_quantity            IN NUMBER DEFAULT NULL,
        i_dt_return           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_context          := i_id_context;
        self.id_supply           := i_id_supply;
        self.id_supply_set       := i_id_supply_set;
        self.id_supply_soft_inst := i_id_supply_soft_inst;
        self.desc_supply         := i_desc_supply;
        self.desc_supply_set     := i_desc_supply_set;
        self.quantity            := i_quantity;
        self.dt_return           := i_dt_return;
    
        RETURN;
    END t_obj_nic_activity_supply;

    -- Member procedures and functions
    MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
    
        l_json.put('ID_CONTEXT', self.id_context);
        l_json.put('ID_SUPPLY', self.id_supply);
        l_json.put('ID_SUPPLY_SET', self.id_supply_set);
        l_json.put('ID_SUPPLY_SOFT_INST', self.id_supply_soft_inst);
        l_json.put('DESC_SUPPLY', self.desc_supply);
        l_json.put('DESC_SUPPLY_SET', self.desc_supply_set);
        l_json.put('QUANTITY', self.quantity);
        l_json.put('DT_RETURN',
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => self.dt_return, i_prof => i_prof));
    
        RETURN l_json;
    END to_json;
END;
/
