CREATE OR REPLACE TYPE t_obj_nnn_epis_activity_det UNDER t_obj_temporal_record
(
-- Author  : ARIEL.MACHADO
-- Created : 6/17/2014 11:56:02 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent a execution of NIC Activity

-- Attributes
    id_nnn_epis_activity_det NUMBER(24),
    id_nnn_epis_activity     NUMBER(24),
    context_record           t_obj_context_record,
    prof_info                t_obj_prof_info,
    cancel_info              t_obj_cancel_info,
    status                   t_obj_status,
    dt_plan                  TIMESTAMP WITH LOCAL TIME ZONE,
    id_epis_documentation    NUMBER(24),
    vital_sign_read_list     table_number,
    lst_activity_task        t_coll_obj_nnn_epis_actv_tsk,
    notes                    CLOB,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_activity_det
    (
        SELF                       IN OUT NOCOPY t_obj_nnn_epis_activity_det,
        i_id_nnn_epis_activity_det IN NUMBER DEFAULT NULL,
        i_id_nnn_epis_activity     IN NUMBER DEFAULT NULL,
        i_context_record           IN t_obj_context_record DEFAULT NULL,
        i_prof_info                IN t_obj_prof_info DEFAULT NULL,
        i_cancel_info              IN t_obj_cancel_info DEFAULT NULL,
        i_status                   IN t_obj_status DEFAULT NULL,
        i_dt_plan                  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_epis_documentation    IN NUMBER DEFAULT NULL,
        i_vital_sign_read_list     IN table_number DEFAULT NULL,
        i_lst_activity_task        IN t_coll_obj_nnn_epis_actv_tsk DEFAULT NULL,
        i_notes                    IN CLOB DEFAULT NULL,
        i_bitemporal_data          IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes   IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_nnn_epis_activity_det AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_activity_det
    (
        SELF                       IN OUT NOCOPY t_obj_nnn_epis_activity_det,
        i_id_nnn_epis_activity_det IN NUMBER DEFAULT NULL,
        i_id_nnn_epis_activity     IN NUMBER DEFAULT NULL,
        i_context_record           IN t_obj_context_record DEFAULT NULL,
        i_prof_info                IN t_obj_prof_info DEFAULT NULL,
        i_cancel_info              IN t_obj_cancel_info DEFAULT NULL,
        i_status                   IN t_obj_status DEFAULT NULL,
        i_dt_plan                  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_epis_documentation    IN NUMBER DEFAULT NULL,
        i_vital_sign_read_list     IN table_number DEFAULT NULL,
        i_lst_activity_task        IN t_coll_obj_nnn_epis_actv_tsk DEFAULT NULL,
        i_notes                    IN CLOB DEFAULT NULL,
        i_bitemporal_data          IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes   IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nnn_epis_activity_det := i_id_nnn_epis_activity_det;
        self.id_nnn_epis_activity     := i_id_nnn_epis_activity;
        self.context_record           := i_context_record;
        self.prof_info                := i_prof_info;
        self.cancel_info              := i_cancel_info;
        self.status                   := i_status;
        self.dt_plan                  := i_dt_plan;
        self.id_epis_documentation    := i_id_epis_documentation;
        self.vital_sign_read_list     := i_vital_sign_read_list;
        self.lst_activity_task        := i_lst_activity_task;
        self.notes                    := i_notes;
        self.bitemporal_data          := i_bitemporal_data;
        self.has_historical_changes   := i_has_historical_changes;
    
        RETURN;
    END t_obj_nnn_epis_activity_det;

    -- Member procedures and functions
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json     json_object_t;
        l_json_lst json_array_t;
    BEGIN
        l_json := (SELF AS t_obj_temporal_record).to_json(i_lang => i_lang, i_prof => i_prof);
    
        l_json.put('ID_NNN_EPIS_ACTIVITY_DET', self.id_nnn_epis_activity_det);
        l_json.put('ID_NNN_EPIS_ACTIVITY', self.id_nnn_epis_activity);
    
        IF self.context_record IS NOT NULL
        THEN
            l_json.put('CONTEXT_RECORD', self.context_record.to_json());
        ELSE
            l_json.put('CONTEXT_RECORD', json_object_t());
        END IF;
    
        IF self.prof_info IS NOT NULL
        THEN
            l_json.put('PROF_INFO', self.prof_info.to_json());
        ELSE
            l_json.put('PROF_INFO', json_object_t());
        END IF;
    
        IF self.cancel_info IS NOT NULL
        THEN
            l_json.put('CANCEL_INFO', self.cancel_info.to_json());
        ELSE
            l_json.put('CANCEL_INFO', json_object_t());
        END IF;
    
        IF self.status IS NOT NULL
        THEN
            l_json.put('STATUS', self.status.to_json());
        ELSE
            l_json.put('STATUS', json_object_t());
        END IF;
    
        l_json.put('DT_PLAN', pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => self.dt_plan, i_prof => i_prof));
    
        l_json.put('ID_EPIS_DOCUMENTATION', self.id_epis_documentation);
    
        l_json.put('VITAL_SIGN_READ_LIST', pk_json_utils.to_json_list(self.vital_sign_read_list));
    
        IF self.lst_activity_task IS NOT empty
        THEN
            FOR i IN 1 .. self.lst_activity_task.count()
            LOOP
                l_json_lst.append(self.lst_activity_task(i).to_json());
            END LOOP;
        END IF;
        l_json.put('LST_ACTIVITY_TASK', l_json_lst);
    
        l_json.put('NOTES', json_object_t.parse(self.notes));
    
        RETURN l_json;
    END to_json;
END;
/
