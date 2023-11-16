-- CHANGED BY: Nuno Neves
-- CHANGE DATE: 2011-09-02
-- CHANGE REASON: ALERT-193627	
CREATE OR REPLACE VIEW V_SUPPLY_TYPE AS
SELECT  st.id_supply_type, 
				st.code_supply_type, 
				st.id_parent, 
				st.id_content, 
				st.flg_available
FROM supply_type st;
--CHANGE END
