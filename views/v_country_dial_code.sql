-- CHANGED BY: André Silva
-- CHANGE DATE: 09/09/2019
-- CHANGE REASON: [EMR-20771] - Phone dial code in patient identification is not autopopulated
CREATE OR REPLACE VIEW v_country_dial_code AS
SELECT c.id_country_dial_code,
       c.code_country_dial_code,
       c.dial_code,
       c.alpha2_code,
       c.id_content,
       c.flg_available
FROM country_dial_code c;
-- CHANGE END: André Silva