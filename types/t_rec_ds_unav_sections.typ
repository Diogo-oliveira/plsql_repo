-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 09/04/2014 08:00
-- CHANGE REASON: [ALERT-267447] Diagnoses improvements: The system must provide the ability to keep records integrity when cancelling some part of it
CREATE OR REPLACE TYPE t_rec_ds_unav_sections UNDER t_rec_ds_sections
(
    tumor_num      NUMBER(24),
    display_number NUMBER(24),
    CONSTRUCTOR FUNCTION t_rec_ds_unav_sections
    (
        SELF           IN OUT NOCOPY t_rec_ds_unav_sections,
        ds_section     t_rec_ds_sections,
        unav_num       NUMBER,
        display_number NUMBER
    ) RETURN SELF AS RESULT
)
INSTANTIABLE FINAL;
/
