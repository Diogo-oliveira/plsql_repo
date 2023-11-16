CREATE OR REPLACE
TRIGGER b_iud_summary_page_section
    BEFORE DELETE OR INSERT OR UPDATE ON summary_page_section
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_summary_page_section := 'SUMMARY_PAGE_SECTION.CODE_SUMMARY_PAGE_SECTION.' ||
                                          :NEW.id_summary_page_section;

        :NEW.code_page_section_subtitle := 'SUMMARY_PAGE_SECTION.CODE_PAGE_SECTION_SUBTITLE.' ||
                                           :NEW.id_summary_page_section;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_summary_page_section
            OR code_translation = :OLD.code_page_section_subtitle;

    ELSIF updating
    THEN
        :NEW.code_summary_page_section  := 'SUMMARY_PAGE_SECTION.CODE_SUMMARY_PAGE_SECTION.' ||
                                           :OLD.id_summary_page_section;
        :NEW.code_page_section_subtitle := 'SUMMARY_PAGE_SECTION.CODE_PAGE_SECTION_SUBTITLE.' ||
                                           :OLD.id_summary_page_section;
    END IF;
END;
/
