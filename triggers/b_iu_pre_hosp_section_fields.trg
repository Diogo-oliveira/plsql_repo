CREATE OR REPLACE TRIGGER b_iu_pre_hosp_section_fields
    BEFORE INSERT OR UPDATE ON pre_hosp_section_fields
    FOR EACH ROW
BEGIN
    pk_announced_arrival.is_trg_ph_sect_flds_val(i_pre_hosp_field => :new.id_pre_hosp_field,
                                                 i_flg_visible    => :new.flg_visible,
                                                 i_flg_mandatory  => :new.flg_mandatory);
END b_iu_pre_hosp_section_fields;
/
