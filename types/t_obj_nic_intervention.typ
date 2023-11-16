CREATE OR REPLACE TYPE t_obj_nic_intervention force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 3/3/2014 11:03:31 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent NIC Intervention

-- Attributes
    id_nic_intervention NUMBER(24),
    nic_code            NUMBER(24),
    name                VARCHAR2(4000),
    definition          VARCHAR2(4000),
    references          CLOB,
    lst_class           t_coll_obj_nic_class,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nic_intervention
    (
        SELF                  IN OUT NOCOPY t_obj_nic_intervention,
        i_id_nic_intervention IN NUMBER DEFAULT NULL,
        i_nic_code            IN NUMBER DEFAULT NULL,
        i_name                IN VARCHAR2 DEFAULT NULL,
        i_definition          IN VARCHAR2 DEFAULT NULL,
        i_references          IN CLOB DEFAULT NULL,
        i_lst_class           IN t_coll_obj_nic_class DEFAULT NULL
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_nic_intervention AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nic_intervention
    (
        SELF                  IN OUT NOCOPY t_obj_nic_intervention,
        i_id_nic_intervention IN NUMBER DEFAULT NULL,
        i_nic_code            IN NUMBER DEFAULT NULL,
        i_name                IN VARCHAR2 DEFAULT NULL,
        i_definition          IN VARCHAR2 DEFAULT NULL,
        i_references          IN CLOB DEFAULT NULL,
        i_lst_class           IN t_coll_obj_nic_class DEFAULT NULL
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nic_intervention := i_id_nic_intervention;
        self.nic_code            := i_nic_code;
        self.name                := i_name;
        self.definition          := i_definition;
        self.references          := i_references;
        self.lst_class           := i_lst_class;
        RETURN;
    END t_obj_nic_intervention;

    -- Member functions and procedures
    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json     json_object_t;
        l_json_lst json_array_t;
    BEGIN
    
        l_json.put('ID_NIC_INTERVENTION', self.id_nic_intervention);
        l_json.put('NIC_CODE', self.nic_code);
        l_json.put('NAME', self.name);
        l_json.put('DEFINITION', self.definition);
        l_json.put('REFERENCES', self.references);
        -- l_json_lst := json_list();
        IF self.lst_class IS NOT empty
        THEN
            FOR i IN 1 .. self.lst_class.count()
            LOOP
                l_json_lst.append(self.lst_class(i).to_json());
            END LOOP;
        END IF;
        l_json.put('LST_CLASS', l_json_lst);
    
        RETURN l_json;
    END to_json;
END;
/
