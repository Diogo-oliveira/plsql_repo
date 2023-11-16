CREATE OR REPLACE TRIGGER b_iu_pre_hosp_step_sections
    BEFORE INSERT OR UPDATE ON pre_hosp_step_sections
    FOR EACH ROW
BEGIN
    pk_announced_arrival.is_trg_ph_step_sect_val(i_pre_hosp_form    => :new.id_pre_hosp_form,
                                                 i_pre_hosp_step    => :new.id_pre_hosp_step,
                                                 i_pre_hosp_section => :new.id_pre_hosp_section,
                                                 i_market           => :new.id_market,
                                                 i_institution      => :new.id_institution,
                                                 i_flg_visible      => :new.flg_visible);
END b_iu_pre_hosp_step_sections;
/
