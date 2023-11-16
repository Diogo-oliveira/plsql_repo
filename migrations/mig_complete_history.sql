-- CHANGED BY: António Neto
-- CHANGE DATE: 16/05/2011 
-- CHANGE REASON: [ALERT-179477] Convert varchar2 to clob - Descrição: No perfil Médico, no INP, no botão da História da Doença (truncated)


BEGIN
    FOR item IN (SELECT ch.id_complete_history, ch.text
                   FROM complete_history ch
									 where ch.text is not null
									 and ch.long_text is null)
    LOOP
        UPDATE complete_history ch
           SET ch.long_text = item.text
         WHERE ch.id_complete_history = item.id_complete_history;
    END LOOP;

END;
/

-- CHANGE END: António Neto