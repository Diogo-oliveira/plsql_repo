-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 09/04/2014 08:00
-- CHANGE REASON: [ALERT-267447] Diagnoses improvements: The system must provide the ability to keep records integrity when cancelling some part of it
CREATE OR REPLACE TYPE t_rec_ds_tumor_sections UNDER t_rec_ds_sections
(
    tumor_num      NUMBER(24),
    display_number NUMBER(24),
    CONSTRUCTOR FUNCTION t_rec_ds_tumor_sections
    (
        SELF           IN OUT NOCOPY t_rec_ds_tumor_sections,
        ds_section     t_rec_ds_sections,
        tumor_num      NUMBER,
        display_number NUMBER
    ) RETURN SELF AS RESULT
) INSTANTIABLE
FINAL;
/

CREATE OR REPLACE TYPE BODY t_rec_ds_tumor_sections AS
    CONSTRUCTOR FUNCTION t_rec_ds_tumor_sections
    (
        SELF           IN OUT NOCOPY t_rec_ds_tumor_sections,
        ds_section     t_rec_ds_sections,
        tumor_num      NUMBER,
        display_number NUMBER
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_ds_cmpt_mkt_rel     := ds_section.id_ds_cmpt_mkt_rel;
        self.id_ds_component_parent := ds_section.id_ds_component_parent;
        self.id_ds_component        := ds_section.id_ds_component;
        self.component_desc         := ds_section.component_desc;
        self.internal_name          := ds_section.internal_name;
        self.flg_component_type     := ds_section.flg_component_type;
        self.flg_data_type          := ds_section.flg_data_type;
        self.slg_internal_name      := ds_section.slg_internal_name;
        self.addit_info_xml_value   := ds_section.addit_info_xml_value;
        self.rank                   := ds_section.rank;
        self.max_len                := ds_section.max_len;
        self.min_value              := ds_section.min_value;
        self.max_value              := ds_section.max_value;
        self.gender                 := ds_section.gender;
        self.age_min_value          := ds_section.age_min_value;
        self.age_min_unit_measure   := ds_section.age_min_unit_measure;
        self.age_max_value          := ds_section.age_max_value;
        self.age_max_unit_measure   := ds_section.age_max_unit_measure;
    
        IF ds_section.component_values IS NOT NULL
        THEN
            self.component_values := ds_section.component_values;
        ELSE
            self.component_values := NEW t_table_ds_items_values();
        END IF;
    
        self.tumor_num      := tumor_num;
        self.display_number := display_number;
    
        RETURN;
    END;
END;
/
-- CHANGE END: Alexandre Santos
