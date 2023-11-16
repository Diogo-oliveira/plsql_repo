-- CHANGED BY:    Nuno Pina Cabral
-- CHANGE DATE:   2013-JUN-04
-- CHANGE REASON: [ALERT-242943] 	Revision of the sample text areas description

-- chamada a pk_translation.upd_bulk_translation STT_REV_AUX_SW_DISTINCT;
DECLARE
    tbl_to_input t_tab_translation;
BEGIN
    SELECT t_rec_translation(code_translation => t.code_translation,
                             table_owner      => t.table_owner,
                             full_code        => t.full_code,
                             table_name       => t.table_name,
                             module           => t.module,
                             desc_lang_1      => sttrev.desc_pt_1,
                             desc_lang_2      => sttrev.desc_en_2,
                             desc_lang_3      => sttrev.desc_es_3,
                             desc_lang_4      => NULL,
                             desc_lang_5      => NULL,
                             desc_lang_6      => sttrev.desc_fr_6,
                             desc_lang_7      => sttrev.desc_uk_7,
                             desc_lang_8      => NULL,
                             desc_lang_9      => NULL,
                             desc_lang_10     => NULL,
                             desc_lang_11     => sttrev.desc_br_11,
                             desc_lang_12     => NULL,
                             desc_lang_13     => NULL,
                             desc_lang_14     => NULL,
                             desc_lang_15     => NULL,
                             desc_lang_16     => sttrev.desc_cl_16,
                             desc_lang_17     => sttrev.desc_mx_17,
                             desc_lang_18     => NULL,
                             desc_lang_19     => NULL,
                             desc_lang_20     => NULL) BULK COLLECT
      INTO tbl_to_input
      FROM stt_rev_aux_sw_distinct sttrev
      JOIN sample_text_type stt
        ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
       AND sttrev.id_software = stt.id_software
      JOIN translation t
        ON stt.code_sample_text_type = t.code_translation
     WHERE stt.flg_available = 'Y';

    pk_translation.upd_bulk_translation(tbl_to_input);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/

-- chamada a pk_translation.upd_bulk_translation STT_REV_AUX_SW_ALL;
DECLARE
    tbl_to_input t_tab_translation;
BEGIN
    SELECT t_rec_translation(code_translation => t.code_translation,
                             table_owner      => t.table_owner,
                             full_code        => t.full_code,
                             table_name       => t.table_name,
                             module           => t.module,
                             desc_lang_1      => sttrev.desc_pt_1,
                             desc_lang_2      => sttrev.desc_en_2,
                             desc_lang_3      => sttrev.desc_es_3,
                             desc_lang_4      => NULL,
                             desc_lang_5      => NULL,
                             desc_lang_6      => sttrev.desc_fr_6,
                             desc_lang_7      => sttrev.desc_uk_7,
                             desc_lang_8      => NULL,
                             desc_lang_9      => NULL,
                             desc_lang_10     => NULL,
                             desc_lang_11     => sttrev.desc_br_11,
                             desc_lang_12     => NULL,
                             desc_lang_13     => NULL,
                             desc_lang_14     => NULL,
                             desc_lang_15     => NULL,
                             desc_lang_16     => sttrev.desc_cl_16,
                             desc_lang_17     => sttrev.desc_mx_17,
                             desc_lang_18     => NULL,
                             desc_lang_19     => NULL,
                             desc_lang_20     => NULL) BULK COLLECT
      INTO tbl_to_input
      FROM stt_rev_aux_sw_all sttrev
      JOIN sample_text_type stt
        ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
      JOIN translation t
        ON stt.code_sample_text_type = t.code_translation
     WHERE stt.flg_available = 'Y';

    pk_translation.upd_bulk_translation(tbl_to_input);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/

-- chamada a pk_translation.ins_bulk_translation STT_REV_AUX_SW_DISTINCT;
DECLARE
    tbl_to_input t_tab_translation;
BEGIN
    SELECT t_rec_translation(code_translation => stt.code_sample_text_type,
                             table_owner      => 'ALERT',
                             full_code        => NULL,
                             table_name       => NULL,
                             module           => 'PFH',
                             desc_lang_1      => sttrev.desc_pt_1,
                             desc_lang_2      => sttrev.desc_en_2,
                             desc_lang_3      => sttrev.desc_es_3,
                             desc_lang_4      => NULL,
                             desc_lang_5      => NULL,
                             desc_lang_6      => sttrev.desc_fr_6,
                             desc_lang_7      => sttrev.desc_uk_7,
                             desc_lang_8      => NULL,
                             desc_lang_9      => NULL,
                             desc_lang_10     => NULL,
                             desc_lang_11     => sttrev.desc_br_11,
                             desc_lang_12     => NULL,
                             desc_lang_13     => NULL,
                             desc_lang_14     => NULL,
                             desc_lang_15     => NULL,
                             desc_lang_16     => sttrev.desc_cl_16,
                             desc_lang_17     => sttrev.desc_mx_17,
                             desc_lang_18     => NULL,
                             desc_lang_19     => NULL,
                             desc_lang_20     => NULL) BULK COLLECT
      INTO tbl_to_input
      FROM stt_rev_aux_sw_distinct sttrev
      JOIN sample_text_type stt
        ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
       AND sttrev.id_software = stt.id_software
     WHERE stt.flg_available = 'Y'
       AND stt.code_sample_text_type NOT IN (SELECT t.code_translation
                                               FROM translation t);

    pk_translation.ins_bulk_translation(tbl_to_input);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/

-- chamada a pk_translation.ins_bulk_translation STT_REV_AUX_SW_ALL;
DECLARE
    tbl_to_input t_tab_translation;
BEGIN
    SELECT t_rec_translation(code_translation => stt.code_sample_text_type,
                             table_owner      => 'ALERT',
                             full_code        => NULL,
                             table_name       => NULL,
                             module           => 'PFH',
                             desc_lang_1      => sttrev.desc_pt_1,
                             desc_lang_2      => sttrev.desc_en_2,
                             desc_lang_3      => sttrev.desc_es_3,
                             desc_lang_4      => NULL,
                             desc_lang_5      => NULL,
                             desc_lang_6      => sttrev.desc_fr_6,
                             desc_lang_7      => sttrev.desc_uk_7,
                             desc_lang_8      => NULL,
                             desc_lang_9      => NULL,
                             desc_lang_10     => NULL,
                             desc_lang_11     => sttrev.desc_br_11,
                             desc_lang_12     => NULL,
                             desc_lang_13     => NULL,
                             desc_lang_14     => NULL,
                             desc_lang_15     => NULL,
                             desc_lang_16     => sttrev.desc_cl_16,
                             desc_lang_17     => sttrev.desc_mx_17,
                             desc_lang_18     => NULL,
                             desc_lang_19     => NULL,
                             desc_lang_20     => NULL) BULK COLLECT
      INTO tbl_to_input
      FROM stt_rev_aux_sw_all sttrev
      JOIN sample_text_type stt
        ON sttrev.intern_name_sample_text_type = stt.intern_name_sample_text_type
     WHERE stt.flg_available = 'Y'
       AND stt.code_sample_text_type NOT IN (SELECT t.code_translation
                                               FROM translation t);

    pk_translation.ins_bulk_translation(tbl_to_input);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || ';');
END;
/

-- CHANGE END
